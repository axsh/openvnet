# -*- coding: utf-8 -*-
require 'spec_helper'
require_relative 'filters/helpers'

include Vnet::Constants::Openflow
include Vnet::Openflow::FlowHelpers

describe Vnet::Openflow::FilterManager do
  let(:datapath) { MockDatapath.new(double, ("a" * 16).to_i) }
  let(:flows) { datapath.current_flows }

  let(:group) { Fabricate(:security_group, rules: "icmp:-1:0.0.0.0/0") }
  let(:interface) { Fabricate(:filter_interface, security_groups: [group]) }

  subject do
    Vnet::Openflow::FilterManager.new(datapath.dp_info).tap { |fm|
      # We do this to simulate a datapath with id 1 so we can use is_remote?
      fm.set_datapath_info Vnet::Openflow::DatapathInfo.new(Fabricate(:datapath, id: 1))
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
    before(:each) { subject.apply_filters wrapper(interface) }

    context "with an interface that's in a single security group" do
      it "applies the flows for that group" do
        expect(flows).to include rule_flow(
          cookie: cookie_id(group),
          match: match_icmp_rule("0.0.0.0/0")
        )
      end
    end

    context "with an interface that's in two security groups" do
      let(:group1) do
        rules = "tcp:22:0.0.0.0/0\nudp:52:10.1.0.1/24"
        Fabricate(:security_group, rules: rules)
      end

      let(:group2) { Fabricate(:security_group, rules: "icmp:-1:10.5.4.3") }
      let(:interface) { Fabricate(:filter_interface, security_groups: [group1, group2]) }

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
       before(:each) { subject.apply_filters wrapper(interface2) }

       let(:interface2) { Fabricate(:filter_interface, security_groups: [group]) }

       it "applies the group's rule flows for both interfaces" do
         expect(flows).to include rule_flow(
           cookie: cookie_id(group),
           match: match_icmp_rule("0.0.0.0/0")
         )

         expect(flows).to include rule_flow({
           cookie: cookie_id(group, interface2),
           match: match_icmp_rule("0.0.0.0/0")},
           interface2
         )
       end
     end
  end

  describe "#removed_interface" do
    before(:each) { subject.apply_filters wrapper(interface) }

    it "Removes filter related flows for a single interface" do
      subject.removed_interface(interface.id)

      expect(flows).not_to include rule_flow(
        cookie: cookie_id(group),
        match: match_icmp_rule("0.0.0.0/0")
      )
    end
  end

  describe "#updated_filter" do
    before(:each) { subject.apply_filters wrapper(interface) }

    context "with new rules in the parameters" do
      before(:each) do
        subject.updated_filter({
          id: group.id,
          rules: "tcp:234:192.168.3.34"
        })
      end

      it "Removes the old rules for a security group" do
        expect(flows).not_to include rule_flow(
          cookie: cookie_id(group),
          match: match_icmp_rule("0.0.0.0/0")
        )
      end

      it "installs the new rules for a security_group" do
        expect(flows).to include rule_flow(
          cookie: cookie_id(group),
          match: match_tcp_rule("192.168.3.34", 234)
        )
      end
    end
  end

  #describe "#disabled_filtering" do
  #  context "with the id of an interface in params" do
  #    before(:each) do
  #      subject.initialized_interface({item_map: wrapper(interface)})
  #      subject.disabled_filtering({id: interface.id})
  #    end

  #    it "removes all security_group rules for the interface" do
  #      expect(flows).not_to include rule_flow(
  #        cookie: cookie_id(group),
  #        match: match_icmp_rule("0.0.0.0/0")
  #      )
  #    end

  #    it "creates a flow that accepts all ingress traffic on the interface" do
  #      expect(flows).to include flow_create(:default,
  #        table: TABLE_INTERFACE_INGRESS_FILTER,
  #        priority: 90,
  #        cookie: Vnet::Openflow::Filters::AcceptAllTraffic.cookie(interface.id),
  #        match_metadata: { interface: interface.id },
  #        goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS
  #      )
  #    end
  #  end
  #end

  #describe "#enabled_filtering" do
  #  let(:interface) do
  #    Fabricate(:filter_interface,
  #      security_groups: [group],
  #      enable_ingress_filtering: false
  #    )
  #  end

  #  context "with the id of an interface in params" do
  #    before(:each) do
  #      subject.initialized_interface({item_map: wrapper(interface)})
  #      subject.enabled_filtering({id: interface.id})
  #    end

  #    it "applies all security_group rules for the interface" do
  #      expect(flows).to include rule_flow(
  #        cookie: cookie_id(group),
  #        match: match_icmp_rule("0.0.0.0/0")
  #      )
  #    end

  #    it "removes the flow that accepts all ingress traffic on the interface" do
  #      expect(flows).not_to include flow_create(:default,
  #        table: TABLE_INTERFACE_INGRESS_FILTER,
  #        priority: 90,
  #        cookie: Vnet::Openflow::Filters::AcceptAllTraffic.cookie(interface.id),
  #        match_metadata: { interface: interface.id },
  #        goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS
  #      )
  #    end

  #  end
  #end

  describe "#added_interface_to_sg" do
    before(:each) do
      subject.apply_filters wrapper(interface)
      subject.apply_filters wrapper(interface2)

      interface2.add_security_group(group)

      subject.added_interface_to_sg(
        id: group.id,
        interface_id: interface2.id,
        interface_cookie_id: group.interface_cookie_id(interface2.id),
        interface_owner_datapath_id: interface2.owner_datapath_id,
        interface_active_datapath_id: interface2.active_datapath_id,
        isolation_ip_addresses: group.ip_addresses
      )
    end

    shared_examples "update isolation for old interfaces" do
      it "updates isolation rules for the interface that was in the group already" do
        expect(flows).to include *iso_flows_for_interfaces(
          group,
          interface,
          [interface, interface2]
        )
      end
    end

    context "with a local interface" do
      let(:interface2) { Fabricate(:filter_interface) }

      include_examples "update isolation for old interfaces"

      it "applies the rule flows for the new interface" do
       expect(flows).to include rule_flow({
         cookie: cookie_id(group, interface2),
         match: match_icmp_rule("0.0.0.0/0")},
         interface2
       )
      end

      it "applies the isolation flows for the new interface" do
        expect(flows).to include *iso_flows_for_interfaces(
          group,
          interface2,
          [interface, interface2]
        )
      end
    end

    context "with a remote interface" do
      let(:interface2) { Fabricate(:filter_interface, owner_datapath_id: 2) }

      include_examples "update isolation for old interfaces"

      it "doesn't apply the rule flows for the new interface" do
       expect(flows).not_to include rule_flow({
         cookie: cookie_id(group, interface2),
         match: match_icmp_rule("0.0.0.0/0")},
         interface2
       )
      end

      it "doesn't apply the isolation flows for the new interface" do
        expect(flows).not_to include *iso_flows_for_interfaces(
          group,
          interface2,
          [interface, interface2]
        )
      end
    end
  end

  describe "#removed_interface_from_sg" do
    let(:group2) do
      rules = "tcp:22:0.0.0.0/0\nudp:52:10.1.0.1/24"
      Fabricate(:security_group, rules: rules)
    end

    # We use this guy to make sure isolation rules aren't removed when they
    # shouldn't be.
    let(:interface3) { Fabricate(:filter_interface, security_groups: [group2])}

    before(:each) do
      subject.apply_filters wrapper(interface)
      subject.apply_filters wrapper(interface2)

      interface2.remove_security_group(group)

      subject.removed_interface_from_sg(
        id: group.id,
        interface_id: interface2.id,
        interface_owner_datapath_id: interface2.owner_datapath_id,
        interface_active_datapath_id: interface2.active_datapath_id,
        isolation_ip_addresses: group.ip_addresses
      )
    end

    shared_examples "update isolation for old interfaces" do
      it "updates isolation rules for the interface that was in the group already" do
        expect(flows).to include *iso_flows_for_interfaces(group, interface, [interface])
        expect(flows).not_to include *iso_flows_for_interfaces(group, interface, [interface2])
      end
    end

    context "with a local interface in two security groups" do
      let(:interface2) { Fabricate(:filter_interface, security_groups: [group, group2]) }

      it "removes the security group's rule flows for the removed interface" do
        expect(flows).not_to include rule_flow({
          cookie: cookie_id(group, interface2),
          match: match_icmp_rule("0.0.0.0/0")},
          interface2
        )
      end

      it "removes the security group's isolation rules for the removed interface" do
        expect(flows).not_to include *iso_flows_for_interfaces(
          group,
          interface2,
          [interface, interface2]
        )
      end

      it "leaves other security groups' rule flows in place" do
        expect(flows).to include rule_flow({
          cookie: cookie_id(group2, interface2),
          match: match_tcp_rule("0.0.0.0/0", 22)},
          interface2
        )

        expect(flows).to include rule_flow({
          cookie: cookie_id(group2, interface2),
          match: match_udp_rule("10.1.0.1/24", 52)},
          interface2
        )
      end

      it "leaves other security groups' isolation flows in place" do
        expect(flows).not_to include *iso_flows_for_interfaces(group, interface2, [interface3])
      end

      include_examples "update isolation for old interfaces"
    end

    context "with a remote interface" do
      let(:interface2) { Fabricate(:filter_interface, owner_datapath_id: 2) }

      include_examples "update isolation for old interfaces"
    end
  end
end
