# -*- coding: utf-8 -*-
require 'spec_helper'

include Vnet::Constants::Openflow
include Vnet::Openflow::FlowHelpers

describe Vnet::Openflow::FilterManager do
  let(:icmpgroup) { Fabricate(:security_group, rules: "icmp:-1:0.0.0.0/0") }
  let(:datapath) { MockDatapath.new(double, ("a" * 16).to_i) }
  let(:flows) { datapath.added_flows }
  let(:interface_wrapper) { Vnet::ModelWrappers::Interface[interface.id] }

  subject { Vnet::Openflow::FilterManager.new(datapath.dp_info) }

  def cookie_id(group, interface)
    group.interface_cookie_id(interface.id)
  end

  SG = Vnet::Openflow::Filters::SecurityGroup
  F = Vnet::Openflow::Filters

  describe "#apply_filters" do
    before(:each) { subject.apply_filters({item_map: interface_wrapper}) }

    context "with an interface that's in a security group " do
      let(:interface) do
        Fabricate(:interface).tap { |i| i.add_security_group(icmpgroup) }
      end

      it "applies the rules for that group" do
        ip = IPAddress::IPv4.new("0.0.0.0/0")
        md = match_ipv4_subnet_src(ip.u32, ip.prefix.to_i)

        expect(flows).to include flow_create(
          :default,
          table: TABLE_INTERFACE_INGRESS_FILTER,
          priority: Vnet::Openflow::Filters::Rule::PRIORITY,
          cookie: SG.cookie(icmpgroup.id, cookie_id(icmpgroup, interface)),
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
  end

end
