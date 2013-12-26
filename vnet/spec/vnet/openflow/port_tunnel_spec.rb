# -*- coding: utf-8 -*-
require 'spec_helper'
require 'trema'

include Vnet::Constants::Openflow

describe Vnet::Openflow::Ports::Tunnel do
  include_context :ofc_double

  describe "install" do
    it "creates tunnel specific flows" do
      datapath = MockDatapath.new(ofc, 10)
      port = Vnet::Openflow::Ports::Base.new(datapath.dp_info, double(port_no: 10, name: 't-a'))
      port.extend(Vnet::Openflow::Ports::Tunnel)
      port.dst_id = 5

      tunnel_manager = double(:tunnel_manager)

      # update_item is now called from port manager.
      # tunnel_manager.should_receive(:update_item)
      # datapath.dp_info.should_receive(:tunnel_manager).and_return(tunnel_manager)

      port.install

      expect(datapath.added_ovs_flows.size).to eq 0
      expect(datapath.added_flows.size).to eq(2 + DATAPATH_IDLE_FLOWCOUNT)

      expect(datapath.added_flows).to include Vnet::Openflow::Flow.create(
                                              TABLE_TUNNEL_PORTS,
                                              30,
                                              {:in_port => 10},
                                              nil,
                                              {:cookie => 10 | (COOKIE_PREFIX_PORT << COOKIE_PREFIX_SHIFT),
                                               :goto_table => TABLE_TUNNEL_NETWORK_IDS})
      expect(datapath.added_flows).to include Vnet::Openflow::Flow.create(
                                              TABLE_VIRTUAL_SRC,
                                              30,
                                              {:in_port => 10},
                                              nil,
                                              {:cookie => 10 | (COOKIE_PREFIX_PORT << COOKIE_PREFIX_SHIFT),
                                               :goto_table => TABLE_ROUTE_INGRESS_INTERFACE})
    end

  end

end
