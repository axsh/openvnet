# -*- coding: utf-8 -*-
require 'spec_helper'
require 'trema'

describe Vnet::Openflow::Switch do
  describe "switch_ready" do

    let(:datapath) { MockDatapath.new(double, 1) }
    let(:dp_info) { datapath.dp_info }

    it "sends messages" do
      allow_any_instance_of(Vnet::Core::TunnelManager).to receive(:create_all_tunnels)
      switch = Vnet::Openflow::Switch.new(datapath)
      switch.switch_ready

      expect(dp_info.sent_messages.size).to eq 2
      expect(dp_info.added_flows.size).to eq DATAPATH_IDLE_FLOWCOUNT
      expect(dp_info.added_ovs_flows.size).to eq 0
    end
  end

  describe "handle_port_desc" do

    let(:datapath) { MockDatapath.new(double, 1) }
    let(:dp_info) { datapath.dp_info }

    context "tunnel" do
      it "should create a port object whose datapath_id is 1" do
        tunnel = double(:tunnel)

        allow_any_instance_of(Vnet::Core::TunnelManager).to receive(:retrieve).and_return(tunnel)

        datapath.create_mock_port_manager
        dp_info.port_manager.set_datapath_info(datapath.datapath_info)

        port_desc = double(:port_desc)
        allow(port_desc).to receive(:port_no).and_return(5)
        allow(port_desc).to receive(:name).exactly(2).times.and_return('t-a')
        allow(port_desc).to receive(:hw_addr).exactly(2).times.and_return(nil)
        allow(port_desc).to receive(:advertised).exactly(1).times.and_return(0)
        allow(port_desc).to receive(:supported).exactly(1).times.and_return(0)

        port = double(:port)
        port_info = double(:port_info)
        allow(port).to receive(:port_number).and_return(5)
        allow(port).to receive(:id).and_return(5)

        allow_any_instance_of(Vnet::Core::Ports::Base).to receive(:new).and_return(port)

        dp_info.port_manager.insert(port_desc)

        expect(dp_info.port_manager.detect(port_number: 5)[:port_number]).to eq 5
      end
    end

    #TODO
    context "eth" do
    end
  end
end
