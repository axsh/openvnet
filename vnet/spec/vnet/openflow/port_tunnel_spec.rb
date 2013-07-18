# -*- coding: utf-8 -*-
require 'spec_helper'
require 'trema'

include Vnet::Constants::Openflow

describe Vnet::Openflow::PortTunnel do
  describe "install" do
    it "creates tunnel specific flows" do
      datapath = MockDatapath.new(double, 10)
      port = Vnet::Openflow::Port.new(datapath, double(port_no: 10), true)
      port.extend(Vnet::Openflow::PortTunnel)
      tunnel_manager = double(:tunnel_manager)
      tunnel_manager.should_receive(:add_port)
      switch = double(:switch)
      switch.should_receive(:tunnel_manager).and_return(tunnel_manager)
      datapath.should_receive(:switch).and_return(switch)

      port.install

      # pp datapath.added_flows

      expect(datapath.added_ovs_flows.size).to eq 0
      expect(datapath.added_flows.size).to eq 2

      expect(datapath.added_flows[0][:table_id]).to eq TABLE_TUNNEL_PORTS
      expect(datapath.added_flows[0][:priority]).to eq 30
      expect(datapath.added_flows[0][:match].in_port).to eq 10
      expect(datapath.added_flows[0][:instructions].size).to eq 1
      expect(datapath.added_flows[0][:instructions][0]).to be_a Trema::Instructions::GotoTable
      expect(datapath.added_flows[0][:instructions][0].table_id).to eq TABLE_TUNNEL_NETWORK_IDS

      expect(datapath.added_flows[1][:table_id]).to eq TABLE_VIRTUAL_SRC
      expect(datapath.added_flows[1][:priority]).to eq 30
      expect(datapath.added_flows[1][:match].in_port).to eq 10
      expect(datapath.added_flows[1][:instructions].size).to eq 1
      expect(datapath.added_flows[1][:instructions][0]).to be_a Trema::Instructions::GotoTable
      expect(datapath.added_flows[1][:instructions][0].table_id).to eq TABLE_ROUTER_ENTRY
    end

  end

end
