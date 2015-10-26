# -*- coding: utf-8 -*-
require 'spec_helper'

include Vnet::Constants::Openflow
include Vnet::Openflow::FlowHelpers

describe Vnet::Core::Filter2Manager do
  
  let(:datapath) { MockDatapath.new(double, ("a" * 16).to_i) }
  let(:dp_info) { datapath.dp_info }
  let(:flows) { dp_info.current_flows }
  let(:deleted_flows) { dp_info.deleted_flows }

  let(:interface) { Fabricate(:filter_interface,
                               ingress_filtering_enabled: false,
                               enable_filtering: true,
                              ) }

  let(:filter) { Fabricate(:filter, mode: "static") }
  let(:filter_static) { Fabricate(:filter_static,
                                  protocol: "tcp",
                                  ipv4_address: "10.101.0.11",
                                  port_number: 80
                                 ) }

  subject do
    Vnet::Core::Filter2Manager.new(datapath.dp_info).tap { |fm|
      # We do this to simulate a datapath with id 1 so we can use is_remote?

      datapath_info = Vnet::Openflow::DatapathInfo.new(Fabricate(:datapath, id: 1))

      fm.set_datapath_info datapath_info

      datapath.dp_info.active_interface_manager.set_datapath_info datapath_info
    }
  end

  describe "#created_item" do
    before(:each) { subject.created_item(filter.to_hash) }
    
    context "with a filter that has both passthrough set to false" do

      it "creates the flows in the ingress and egress tables" do
        expect(flows).to include flow_create(table: TABLE_INTERFACE_INGRESS_FILTER,
                                             priority: 50,
                                             match_interface: interface.id,
                                             match: {
                                               eth_type: ETH_TYPE_IPV4,
                                               ipv4_src: "10.101.0.11",
                                               ip_proto: IPV4_PROTOCOL_TCP,
                                               tcp_dst: 80
                                             }
                                            )
        expect(flows).to include flow_create(table: TABLE_INTERFACE_EGRESS_FILTER,
                                             priority: 50,
                                             match_interface: interface.id,
                                             match: {
                                               eth_type: ETH_TYPE_IPV4,
                                               ipv4_dst: "10.101.0.11",
                                               ip_proto: IPV4_PROTOCOL_TCP,
                                               tcp_dst: 80
                                             }
                                            )        
      end      
    end
  end
end
