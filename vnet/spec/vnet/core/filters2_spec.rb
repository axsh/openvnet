# -*- coding: utf-8 -*-

require 'spec_helper'

include Vnet::Constants::Openflow
include Vnet::Openflow::FlowHelpers


def flow(params)
  flow_create(
    table: params[:table],
    goto_table: params[:goto_table],
    priority: params[:priority],
    match_interface: params[:interface_id],
    cookie: params[:id] | COOKIE_TYPE_FILTER2,
    match: params[:match]
  )
end

def merged_hash_array(hash_array)
  return hash_array.inject(&:merge)
end

def ingress_tables(passthrough)
   {
    table: TABLE_INTERFACE_INGRESS_FILTER,
    goto_table: passthrough ? TABLE_OUT_PORT_INTERFACE_INGRESS : nil
   }
end

def egress_tables(passthrough)
  {
    table: TABLE_INTERFACE_EGRESS_FILTER,
    goto_table: passthrough ? TABLE_INTERFACE_EGRESS_VALIDATE : nil,
  }
end

def protocol_type(protocol, port_number)
  case protocol
    when IPV4_PROTOCOL_TCP then
      {
        tcp_dst: port_number,
        ip_proto: protocol
      }
    when IPV4_PROTOCOL_UDP then
      {
        udp_dst: port_number,
        ip_proto: protocol
      }
    end
end

def rule_flow(direction, protocol, ipv4_address, prefix, port_number)
  case direction
  when "ingress" then
    match_ipv4_subnet_src(ipv4_address, prefix).merge(protocol_type(protocol, port_number))
  when "egress" then
    match_ipv4_subnet_dst(ipv4_address, prefix).merge(protocol_type(protocol, port_number))
  else
    return
  end
end

def static_priority(prefix, port, passthrough)
  (prefix << 1) + ((port.nil? || port == 0) ? 0 : 2) + (passthrough ? 1 : 0)
end

describe Vnet::Core::Filter2Manager do

  use_mock_event_handler

  let(:datapath) { create_mock_datapath }
  let(:flows) { datapath.dp_info.current_flows }
  let(:deleted_flows) { datapath.dp_info.deleted_flows }

  let(:filter2_manager) { datapath.dp_info.filter2_manager }
  let(:interface_manager) { datapath.dp_info.interface_manager }

  let(:filter) { Fabricate(:filter,
                           uuid: "fil-test",
                           interface_id: 1,
                           mode: "static",
                          ) }


  let(:filter_static) { Fabricate(:static_tcp_pass) }

  before(:each) do
    filter2_manager.publish(Vnet::Event::FILTER_ACTIVATE_INTERFACE, id: :interface, interface_id: 1)
  end

  describe "#created_item" do
    before(:each) do
      filter2_manager.publish(Vnet::Event::FILTER_CREATED_ITEM, filter.to_hash)
      sleep(3)
    end

    context "with with passthrough set to false" do
      it "creates the a filter item" do

        filter_hash = [
            filter.to_hash,
            ingress_tables(filter.ingress_passthrough),
            { priority: 10 }
        ]

        expect(flows).to include flow(merged_hash_array(filter_hash))

        filter_hash = [
          filter.to_hash,
          ingress_tables(filter.ingress_passthrough),
          { priority: 10 }
        ]

        expect(flows).to include flow(merged_hash_array(filter_hash))

      end
    end

    context "with with passthrough set to true" do
      let(:filter) { Fabricate(:filter,
                               uuid: "fil-test",
                               interface_id: 1,
                               mode: "static",
                               egress_passthrough: true,
                               ingress_passthrough: true
                              )
      }

      it "creates the a filter item" do

        filter_hash = [ filter.to_hash, ingress_tables(filter.ingress_passthrough), { priority: 10 } ]
        expect(flows).to include flow(merged_hash_array(filter_hash))

        filter_hash = [ filter.to_hash, ingress_tables(filter.ingress_passthrough), { priority: 10 } ]
        expect(flows).to include flow(merged_hash_array(filter_hash))

      end
    end
  end

  describe "#updated_item" do
    before(:each) do
      filter2_manager.publish(Vnet::Event::FILTER_UPDATED, filter.to_hash)
      sleep(3)
    end

    context "with with ingress passthrough set false, egress_passthrough set true" do
      it "updates the a filter item" do
      end
    end

    context "with with ingress passthrough set true, egress_passthrough set false" do
      it "updates the a filter item" do
      end
    end
  end

  describe "#added_static" do
    before(:each) do
      filter2_manager.publish(Vnet::Event::FILTER_CREATED_ITEM, filter.to_hash)
      sleep(3)

      model_hash = filter_static.to_hash.merge(id: filter.id, static_id: filter_static.id)
      filter2_manager.publish(Vnet::Event::FILTER_ADDED_STATIC, model_hash)
      sleep(3)
    end

    context "when protocol is tcp and passthrough is enabled" do
      it "adds the static" do

        filter_hash = [
          filter.to_hash,
          ingress_tables(filter_static.passthrough),
          { priority: 20 + static_priority(filter_static.ipv4_src_prefix,
                                           filter_static.passthrough,
                                           filter_static.port_src_first) },
          { match: rule_flow("ingress", IPV4_PROTOCOL_TCP,
                             filter_static.port_src_first,
                             filter_static.ipv4_src_address,
                             filter_static.ipv4_src_prefix) }
        ]
        expect(flows).to include flow(merged_hash_array(filter_hash))

        filter_hash = [
          filter.to_hash,
          egress_tables(filter_static.passthrough),
          { priority: 20 + static_priority(filter_static.ipv4_dst_prefix,
                                           filter_static.passthrough,
                                           filter_static.port_dst_first) },
          { match: rule_flow("egress", IPV4_PROTOCOL_TCP,
                       filter_static.port_dst_first,
                       filter_static.ipv4_dst_address,
                       filter_static.ipv4_dst_prefix) }
        ]
        expect(flows).to include flow(merged_hash_array(filter_hash))

      end
    end
 end

  describe "#remove static" do
    before(:each) do
    end

    it "removes a static rule" do
    end
  end
end
