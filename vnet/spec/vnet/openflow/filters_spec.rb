# -*- coding: utf-8 -*-
require 'spec_helper'
require_relative 'filters/helpers'

include Vnet::Constants::Openflow
include Vnet::Openflow::FlowHelpers

describe Vnet::Openflow::FilterManager do
  let(:datapath) { MockDatapath.new(double, ("a" * 16).to_i) }
  let(:flows) { datapath.current_flows }

  subject { Vnet::Openflow::FilterManager.new(datapath.dp_info) }

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
        Fabricate(:interface).tap { |i| i.add_security_group(group) }
      end

      it "applies the flows for that group" do
        expect(flows).to include rule_flow(
          cookie: cookie_id(group),
          match: match_icmp_rule("0.0.0.0/0")
        )
      end
    end

    context "with an interface that has no security groups" do
      let(:interface) { Fabricate(:interface) }

      F = Vnet::Openflow::Filters
      it "applies a flow that accepts all traffic on the interface" do
        expect(flows).to include flow_create(:default,
          table: TABLE_INTERFACE_INGRESS_FILTER,
          priority: Vnet::Openflow::Filters::Rule::PRIORITY,
          cookie: F::AcceptAllTraffic.cookie(interface.id),
          match_metadata: {interface: interface.id},
          goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS
        )
      end
    end

    context "with an interface that's in two security groups" do
      let(:group1) do
        rules = "tcp:22:0.0.0.0/0\nudp:52:10.1.0.1/24"
        Fabricate(:security_group, rules: rules)
      end
      let(:group2) { Fabricate(:security_group, rules: "icmp:-1:10.5.4.3") }
      let(:interface) do
        Fabricate(:interface).tap { |i|
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
  end

  describe "#remove_filters" do
    let(:group) do
      rules = "tcp:22:0.0.0.0/0"
      Fabricate(:security_group, rules: rules)
    end

    let(:interface) do
      Fabricate(:interface).tap { |i|
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

end
