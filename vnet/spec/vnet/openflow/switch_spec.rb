# -*- coding: utf-8 -*-
require 'spec_helper'
require 'trema'

describe Vnet::Openflow::Switch do
  describe "switch_ready" do
    it "create default flows" do
      datapath = MockDatapath.new(double, 1)
      Vnet::Openflow::TunnelManager.any_instance.stub(:create_all_tunnels)
      switch = Vnet::Openflow::Switch.new(datapath)
      switch.create_default_flows

      expect(datapath.sent_messages.size).to eq 0
      expect(datapath.added_flows.size).to eq 41
      expect(datapath.added_ovs_flows.size).to eq 0
    end

    it "sends messages" do
      datapath = MockDatapath.new(double, 1)
      Vnet::Openflow::TunnelManager.any_instance.stub(:create_all_tunnels)
      switch = Vnet::Openflow::Switch.new(datapath)
      switch.switch_ready

      expect(datapath.sent_messages.size).to eq 2
      expect(datapath.added_flows.size).to eq 0
      expect(datapath.added_ovs_flows.size).to eq 0
    end
  end

  describe "handle_port_desc" do
    context "tunnel" do
      it "should create a port object whose datapath_id is 1" do
        ofc = double(:ofc)
        dp = MockDatapath.new(ofc, 1)
        Vnet::Openflow::TunnelManager.any_instance.stub(:create_all_tunnels)
        dp.create_mock_port_manager
        port_desc = double(:port_desc)
        port_desc.should_receive(:port_no).exactly(3).times.and_return(5)
        port_desc.should_receive(:name).exactly(1).times.and_return('t-a')
        port_desc.should_receive(:hw_addr).exactly(1).times.and_return(nil)
        port_desc.should_receive(:advertised).exactly(1).times.and_return(0)
        port_desc.should_receive(:supported).exactly(1).times.and_return(0)

        port = double(:port)
        port_info = double(:port_info)
        port.should_receive(:port_number).exactly(2).times.and_return(5)
        port.should_receive(:port_info).exactly(3).times.and_return(port_info)
        port.should_receive(:to_hash).exactly(1).times.and_return({})

        port.should_receive(:extend).and_return(Vnet::Openflow::Ports::Tunnel)
        port.should_receive(:install)
        port_info.should_receive(:name).exactly(3).times.and_return("t-src1dst3")

        Vnet::Openflow::Ports::Base.stub(:new).and_return(port)

        dp.port_manager.insert(port_desc)

        expect(dp.port_manager.ports[5]).to eq port
      end
    end

    #TODO
    context "eth" do
    end
  end
end
