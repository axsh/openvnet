# -*- coding: utf-8 -*-
require 'spec_helper'

include Vnet::Constants::Openflow
include Vnet::Openflow::FlowHelpers

describe Vnet::Openflow::FilterManager do
  let(:icmpgroup) { Fabricate(:security_group, rules: "icmp:-1:0.0.0.0/0") }
  let(:datapath) { MockDatapath.new(double, ("a" * 16).to_i) }
  let(:flows) { datapath.added_flows }
  let(:iface_metadata) { subject.md_create(interface: interface.id) }

  subject { Vnet::Openflow::FilterManager.new(datapath.dp_info) }

  def cookie_id(group, interface)
    group.interface_cookie_id(interface.id)
  end

  SG = Vnet::Openflow::Filters::SecurityGroup

  describe "#apply_filters" do
    context "with an interface that's in a security group " do
      let(:interface) do
        Fabricate(:interface).tap { |i| i.add_security_group(icmpgroup) }
      end
      let(:interface_wrapper) { Vnet::ModelWrappers::Interface[interface.id] }

      it "applies the rules for that group" do
        subject.apply_filters({item_map: interface_wrapper})

        ip = IPAddress::IPv4.new("0.0.0.0/0")
        md = match_ipv4_subnet_src(ip.u32, ip.prefix.to_i).merge(iface_metadata)

        expect(flows).to include flow_create(
          :default,
          table: TABLE_INTERFACE_INGRESS_FILTER,
          priority: 10,
          cookie: SG.cookie(icmpgroup.id, cookie_id(icmpgroup, interface)),
          match_metadata: {interface: interface.id},
          match: md.merge({ip_proto: IPV4_PROTOCOL_ICMP}),
          goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS
        )
      end
    end

#     context "with an interface that has no security groups" do
#       let(:interface) { Fabricate(:interface) }

#       it "applies a flow to accept all traffic on the interface" do
#         subject.apply_rules(interface.id)
#         expect(flows).to include Vnet::Openflow::Flow.create(
#           TABLE_INTERFACE_INGRESS_FILTER,
#           Vnet::Openflow::SecurityGroups::Rule::RULE_PRIORITY,
#           subject.md_create(interface: interface.id),
#           nil,
#           {
#             cookie: interface.id | COOKIE_TYPE_SECURITY_GROUP |
#               COOKIE_SG_TYPE_TAG |
#               COOKIE_TAG_INGRESS_ACCEPT_ALL,
#             goto_table: TABLE_OUTPUT_INTERFACE_INGRESS
#           }
#         )
#       end
    # end
  end

end
