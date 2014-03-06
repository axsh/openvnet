# -*- coding: utf-8 -*-
require 'spec_helper'
require_relative 'filters/helpers'

include Vnet::Constants::Openflow
include Vnet::Openflow::FlowHelpers

describe Vnet::Openflow::FilterManager do
  let(:datapath) { MockDatapath.new(double, ("a" * 16).to_i) }
  let(:flows) { datapath.current_flows }
  let(:deleted_flows) { datapath.deleted_flows }

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

    context "with a group that has rules with faulthy syntax" do
      let(:group) do
        rules = %{
          # I am a comment
          I'm not even a rule at all
          joske:22:0.0.0.0/0
          tcp:i ain't no port:10.0.0.1/24
          udp:52:no ip for you
          tcp:22:10.1.0.0/24
          icmp::0.0.0.0/0:something else
        }
        Fabricate(:security_group, rules: rules)
      end

      it "skips the faulty syntax rules and still applies the correct ones" do
        expect(flows).to include rule_flow(
          cookie: cookie_id(group),
          match: match_tcp_rule("10.1.0.0/24", 22)
        )

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

     context "with a security group referencing another security group" do
       let(:reffee) { Fabricate(:security_group) }
       let(:group) { Fabricate(:security_group, rules: "tcp:22:#{reffee.canonical_uuid}") }

       let(:ref_intf1) { Fabricate(:filter_interface, security_groups: [reffee]) }
       let(:ref_intf2) { Fabricate(:filter_interface, security_groups: [reffee]) }

       let(:interface) do
         # Dirty hack to make sure the referenced interfaces are created first
         ref_intf1;ref_intf2
         Fabricate(:filter_interface, security_groups: [group])
       end

       it "applies the rule for each interface in the referenced group" do
         #TODO: Test for interfaces with multiple ip leases
         ref_intf1.ip_addresses.each { |a|
           expect(flows).to include rule_flow(
             cookie: ref_cookie_id(group),
             match: match_tcp_rule("#{a.ipv4_address_s}/32", 22)
           )
         }

         ref_intf2.ip_addresses.each { |a|
           expect(flows).to include rule_flow(
             cookie: ref_cookie_id(group),
             match: match_tcp_rule("#{a.ipv4_address_s}/32", 22)
           )
         }
       end
     end
  end

  describe "#remove_filters" do
    before(:each) do
      subject.apply_filters wrapper(interface)
      subject.remove_filters(interface.id)
    end

    it "Removes filter related flows for a single interface" do
      expected_flow = rule_flow(
        cookie: cookie_id(group),
        match: match_icmp_rule("0.0.0.0/0")
      )

      expect(flows).not_to include expected_flow
      expect(deleted_flows).to include expected_flow
    end

   context "with a security group referencing another security group" do
     let(:reffee) { Fabricate(:security_group) }
     let(:group) { Fabricate(:security_group, rules: "tcp:22:#{reffee.canonical_uuid}") }

     let(:ref_intf1) { Fabricate(:filter_interface, security_groups: [reffee]) }
     let(:ref_intf2) { Fabricate(:filter_interface, security_groups: [reffee]) }

     let(:interface) do
       # Dirty hack to make sure the referenced interfaces are created first
       ref_intf1;ref_intf2
       Fabricate(:filter_interface, security_groups: [group])
     end

     it "removes the rule for each interface in the referenced group" do
       intf1_flows = reference_flows_for("tcp:22", ref_intf1)
       expect(flows).not_to include *intf1_flows
       expect(deleted_flows).to include *intf1_flows

       intf2_flows = reference_flows_for("tcp:22", ref_intf2)
       expect(flows).not_to include *intf2_flows
       expect(deleted_flows).to include *intf2_flows
     end
   end
  end

  describe "#updated_sg_rules" do
    before(:each) { subject.apply_filters wrapper(interface) }

    context "with new rules in the parameters" do
      before(:each) do
        subject.updated_sg_rules({
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

      it "installs the new rules for a security group" do
        expect(flows).to include rule_flow(
          cookie: cookie_id(group),
          match: match_tcp_rule("192.168.3.34", 234)
        )
      end
    end
  end

  describe "#updated_sg_ip_addresses" do
    let(:interface2) { Fabricate(:filter_interface) }

    before(:each) do
      subject.apply_filters wrapper(interface)
      subject.apply_filters wrapper(interface2)

      interface2.add_security_group(group)

      subject.updated_sg_ip_addresses(
        id: group.id,
        ip_addresses: group.ip_addresses
      )
    end

    it "updates isolation rules for all local interfaces in the group" do
      expect(flows).to include *iso_flows_for_interfaces(
        group,
        interface,
        [interface, interface2]
      )

      # Isolation hasn't been updated for interface2 because we haven't called
      # apply_filters or added_interface_to_sg for interface2. In the real
      # world this will be called and it doesn't matter if it happens before
      # or after updated_sg_ip_addresses
    end
  end

  describe "#added_interface_to_sg" do
    before(:each) do
      subject.apply_filters wrapper(interface)
      subject.apply_filters wrapper(interface2)

      interface2.add_security_group(group)

      subject.added_interface_to_sg(
        id: group.id,
        interface_id: interface2.id,
        interface_cookie_id: group.interface_cookie_id(interface2.id)
      )
    end

    context "with a local interface with filtering enabled" do
      let(:interface2) { Fabricate(:filter_interface) }

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
          [interface]
        )
      end

      # it doesn't update isolation rules for the interfaces that already were
      # in the group. updated_sg_ip_addresses does that.
    end

    context "with a local interface with filtering disabled" do
      let(:interface2) do
        Fabricate(:filter_interface, ingress_filtering_enabled: false)
      end

      it "doesn't apply any flows for the new interface" do
        expect(flows).not_to include rule_flow({
          cookie: cookie_id(group, interface2),
          match: match_icmp_rule("0.0.0.0/0")},
          interface2
        )

        expect(flows).not_to include *iso_flows_for_interfaces(
          group,
          interface2,
          [interface]
         )
      end
    end

    context "with a remote interface" do
      let(:interface2) { Fabricate(:filter_interface, owner_datapath_id: 2) }

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

    before(:each) do
      subject.apply_filters wrapper(interface)
      subject.apply_filters wrapper(interface2)

      interface2.remove_security_group(group)

      subject.removed_interface_from_sg(
        id: group.id,
        interface_id: interface2.id,
        interface_owner_datapath_id: interface2.owner_datapath_id,
        interface_active_datapath_id: interface2.active_datapath_id,
      )
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
    end
  end
end
