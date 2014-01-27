# -*- coding: utf-8 -*-
require 'spec_helper'
require_relative 'filters/helpers'

include Vnet::Constants::Openflow
include Vnet::Openflow::FlowHelpers

describe Vnet::Openflow::FilterManager do
  let(:datapath) { MockDatapath.new(double, ("a" * 16).to_i) }
  let(:flows) { datapath.added_flows }

  subject do
    Vnet::Openflow::FilterManager.new(datapath.dp_info).tap { |fm|
      fm.set_datapath_info OpenStruct.new({id: 1})
    }
  end

  describe "#initialize" do
    it "applies a flow that accepts all arp traffic" do
      expect(flows).to include flow_create(:default,
        table: TABLE_INTERFACE_INGRESS_FILTER,
        priority: 90,
        cookie: Vnet::Openflow::Filters::AcceptIngressArp.cookie,
        match: { eth_type: ETH_TYPE_ARP },
        goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS
      )
    end
  end

  describe "#apply_filters" do
    before(:each) { subject.apply_filters({item_map: wrapper(interface)}) }

    context "with an interface that's in a single security group " do
      let(:group) { Fabricate(:security_group, rules: "icmp:-1:0.0.0.0/0") }
      let(:interface) do
        Fabricate(:interface, active_datapath_id: 1).tap { |i|
          i.add_security_group(group)
        }
      end

      it "applies the flows for that group" do
        expect(flows).to include rule_flow(
          cookie: cookie_id(group),
          match: match_icmp_rule("0.0.0.0/0")
        )
      end
    end

    #
    # This probably won't be the final behaviour anyway...
    #

    # context "with an interface that has no security groups" do
    #   let(:interface) { Fabricate(:interface) }

    #   F = Vnet::Openflow::Filters
    #   it "applies a flow that accepts all traffic on the interface" do
    #     expect(flows).to include flow_create(:default,
    #       table: TABLE_INTERFACE_INGRESS_FILTER,
    #       priority: Vnet::Openflow::Filters::Rule::PRIORITY,
    #       cookie: F::AcceptAllTraffic.cookie(interface.id),
    #       match_metadata: {interface: interface.id},
    #       goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS
    #     )
    #   end
    # end

    context "with an interface that's in two security groups" do
      let(:group1) do
        rules = "tcp:22:0.0.0.0/0\nudp:52:10.1.0.1/24"
        Fabricate(:security_group, rules: rules)
      end
      let(:group2) { Fabricate(:security_group, rules: "icmp:-1:10.5.4.3") }
      let(:interface) do
        Fabricate(:interface, active_datapath_id: 1).tap { |i|
          i.add_security_group(group1)
          i.add_security_group(group2)
        }
      end

      it "applies flows for all groups" do
        expect(flows).to include rule_flow(
          cookie: cookie_id(group1),
          match: match_tcp_rule("0.0.0.0/0", 22),
        )

        expect(flows).to include rule_flow(
          cookie: cookie_id(group1),
          match: match_udp_rule("10.1.0.1/24", 52)
        )

        expect(flows).to include rule_flow(
          cookie: cookie_id(group2),
          match: match_icmp_rule("10.5.4.3/32")
        )
      end
    end

    context "with a security group that has two interfaces in it" do
      let(:group) { Fabricate(:security_group, rules: "tcp:456:10.10.10.10") }

      let(:interface) do
        Fabricate(:interface, active_datapath_id: 1).tap { |i|
          i.add_security_group(group)
        }
      end

      let(:interface2) do
        Fabricate(:interface, active_datapath_id: 1).tap { |i|
          i.add_security_group(group)
        }
      end

      before(:each) { subject.apply_filters({item_map: wrapper(interface2)}) }

      it "applies the group's flows for both interfaces" do
        expect(flows).to include rule_flow(
          cookie: cookie_id(group),
          match: match_tcp_rule("10.10.10.10", 456)
        )

        expect(flows).to include rule_flow({
          cookie: cookie_id(group, interface2),
          match: match_tcp_rule("10.10.10.10", 456)},
          interface2
        )
      end
    end
  end

  describe "#remove_filters" do
    let(:group) do
      rules = "tcp:22:0.0.0.0/0"
      Fabricate(:security_group, rules: rules)
    end

    let(:interface) do
      Fabricate(:interface, active_datapath_id: 1).tap { |i|
        i.add_security_group(group)
      }
    end

    before(:each) { subject.apply_filters({item_map: wrapper(interface)}) }

    it "Removes filter related flows for a single interface" do
      subject.remove_filters({id: interface.id})

      expect(flows).not_to include rule_flow(
        cookie: cookie_id(group),
        match: match_tcp_rule("0.0.0.0/0", 22),
      )
    end
  end

  describe "#update_item" do
    let(:group) do
      rules = "tcp:22:0.0.0.0/0"
      Fabricate(:security_group, rules: rules)
    end

    let(:interface) do
      Fabricate(:interface, active_datapath_id: 1).tap { |i|
        i.add_security_group(group)
      }
    end

    before(:each) { subject.apply_filters({item_map: wrapper(interface)}) }

    context "with {event: :update_rules} in the parameters" do
      before(:each) do
        subject.update_item({
          event: :update_rules,
          id: group.id,
          rules: "tcp:234:192.168.3.34"
        })
      end

      it "Removes the old rules for a security group" do
        expect(flows).not_to include rule_flow(
          cookie: cookie_id(group),
          match: match_tcp_rule("0.0.0.0/0", 22)
        )
      end

      it "install the new rules for a security_group" do
        expect(flows).to include rule_flow(
          cookie: cookie_id(group),
          match: match_tcp_rule("192.168.3.34", 234)
        )
      end
    end
  end
end
