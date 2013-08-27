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
      expect(datapath.added_flows.size).to eq 33
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
end
