# -*- coding: utf-8 -*-
require 'spec_helper'

include Vnet::Constants::Openflow
include Vnet::Openflow::FlowHelpers

describe Vnet::Openflow::FilterManager do
  let(:datapath) { MockDatapath.new(double, ("a" * 16).to_i) }
  let(:flows) { datapath.added_flows }
  let(:interface_wrapper) { Vnet::ModelWrappers::Interface[interface.id] }

  subject { Vnet::Openflow::FilterManager.new(datapath.dp_info) }

  SG = Vnet::Openflow::Filters::SecurityGroup
  F = Vnet::Openflow::Filters

  def cookie_id(group)
    SG.cookie(group.id, group.interface_cookie_id(interface.id))
  end

  describe "#apply_filters" do
    before(:each) { subject.apply_filters({item_map: interface_wrapper}) }

    context "with an interface that's in a single security group " do
      let(:group) { Fabricate(:security_group, rules: "icmp:-1:0.0.0.0/0") }
      let(:interface) do
        Fabricate(:interface).tap { |i| i.add_security_group(group) }
      end

      it "applies the flows for that group" do
        ip = IPAddress::IPv4.new("0.0.0.0/0")
        md = match_ipv4_subnet_src(ip.u32, ip.prefix.to_i)

        expect(flows).to include flow_create(
          :default,
          table: TABLE_INTERFACE_INGRESS_FILTER,
          priority: Vnet::Openflow::Filters::Rule::PRIORITY,
          cookie: cookie_id(group),
          match_metadata: {interface: interface.id},
          match: md.merge({ip_proto: IPV4_PROTOCOL_ICMP}),
          goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS
        )
      end
    end

    context "with an interface that has no security groups" do
      let(:interface) { Fabricate(:interface) }

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

      def match_rule(source_ip)
        ip = IPAddress::IPv4.new(source_ip)
        match_ipv4_subnet_src(ip.u32, ip.prefix.to_i)
      end

      def match_tcp_rule(source_ip, port)
        match_rule(source_ip).merge({
          ip_proto: IPV4_PROTOCOL_TCP,
          tcp_dst: port
        })
      end

      def match_udp_rule(source_ip, port)
        match_rule(source_ip).merge({
          ip_proto: IPV4_PROTOCOL_UDP,
          udp_dst: port
        })
      end

      def match_icmp_rule(source_ip)
        match_rule(source_ip).merge({ ip_proto: IPV4_PROTOCOL_ICMP })
      end

      def rule_flow(rule_hash)
        flow_hash = rule_hash.merge({
          table: TABLE_INTERFACE_INGRESS_FILTER,
          priority: Vnet::Openflow::Filters::Rule::PRIORITY,
          match_metadata: {interface: interface.id},
          goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS
        })
        flow_create(:default, flow_hash)
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

end
