# -*- coding: utf-8 -*-

require 'spec_helper'

include Vnet::Constants::Openflow
include Vnet::Openflow::FlowHelpers

describe Vnet::Core::Filter2Manager do

  use_mock_event_handler

  let(:datapath) { create_mock_datapath }
  let(:flows) { datapath.dp_info.current_flows }
  let(:deleted_flows) { datapath.dp_info.deleted_flows }

  let(:filter2_manager) { datapath.dp_info.filter2_manager }
  let(:interface_manager) { datapath.dp_info.interface_manager }

  let(:interface) { Fabricate(:filter_interface,
                              uuid: "if-filter",
                              ingress_filtering_enabled: false,
                              enable_filtering: true
                             ) }
  
  let(:filter) { Fabricate(:filter,
                           uuid: "fil-test",
                           interface_id: "if-filter",
                           mode: "static",
                          ) }

  let(:filter_static) { Fabricate(:filter_static,
                                  protocol: "tcp",
                                  ipv4_src_address: IPAddr.new("10.101.0.11").to_i,
                                  ipv4_dst_address: IPAddr.new("10.101.0.11").to_i,
                                  port_src_first: 80,
                                  port_src_last: 80,
                                  port_dst_first: 80,
                                  port_dst_last: 80,
                                  ipv4_src_prefix: 32,
                                  ipv4_dst_prefix: 32,
                                  passthrough: true
                                 ) }
  before(:each) do
    filter2_manager.publish(Vnet::Event::FILTER_ACTIVATE_INTERFACE, id: :interface, interface_id: 0)
  end

  describe "#created_item" do
    before(:each) do
      filter2_manager.publish(Vnet::Event::FILTER_CREATED_ITEM, filter.to_hash)
      sleep(3)
    end

    context "with with passthrough set to false" do
      it "creates the a filter item" do
        expect(flows).to include flow_create(table: TABLE_INTERFACE_INGRESS_FILTER,
                                             priority: 10,
                                             match_interface: 0,
                                             cookie: filter.id | COOKIE_TYPE_FILTER2
                                            )
        expect(flows).to include flow_create(table: TABLE_INTERFACE_EGRESS_FILTER,
                                             priority: 10,
                                             match_interface: 0,
                                             cookie: filter.id | COOKIE_TYPE_FILTER2
                                            )
      end
    end

    context "with with passthrough set to true" do
      let(:filter) { Fabricate(:filter,
                               uuid: "fil-test",
                               interface_id: "if-filter",
                               mode: "static",
                               egress_passthrough: true,
                               ingress_passthrough: true
                              ) }
      it "creates the a filter item" do
        expect(flows).to include flow_create(table: TABLE_INTERFACE_INGRESS_FILTER,
                                             goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS,
                                             priority: 10,
                                             match_interface: 0,
                                             cookie: 1 | COOKIE_TYPE_FILTER2
                                            )
        expect(flows).to include flow_create(table: TABLE_INTERFACE_EGRESS_FILTER,
                                             goto_table: TABLE_INTERFACE_EGRESS_VALIDATE,
                                             priority: 10,
                                             match_interface: 0,
                                             cookie: 1 | COOKIE_TYPE_FILTER2
                                            )
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
        expect(flows).to include flow_create(table: TABLE_INTERFACE_INGRESS_FILTER,
                                             goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS,
                                             priority: 20 + 32,
                                             match_interface: 0,
                                             cookie: 1 | COOKIE_TYPE_FILTER2,
                                             match: {
                                               eth_type: ETH_TYPE_IPV4,
                                               ipv4_src: IPAddr.new("10.101.0.11").to_i,
                                               ipv4_src_mask: IPV4_BROADCAST << (32 - 32),
                                               ip_proto: IPV4_PROTOCOL_TCP,
                                               tcp_dst: 80
                                             })

        expect(flows).to include flow_create(table: TABLE_INTERFACE_EGRESS_FILTER,
                                             goto_table: TABLE_INTERFACE_EGRESS_VALIDATE,
                                             priority: 20 + 32,
                                             match_interface: 0,
                                             cookie: 1 | COOKIE_TYPE_FILTER2,
                                             match: {
                                               eth_type: ETH_TYPE_IPV4,
                                               ipv4_dst: IPAddr.new("10.101.0.11").to_i,
                                               ipv4_dst_mask: IPV4_BROADCAST << (32 - 32),
                                               ip_proto: IPV4_PROTOCOL_TCP,
                                               tcp_dst: 80
                                             })
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
