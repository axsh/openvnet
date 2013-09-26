# -*- coding: utf-8 -*-
require 'spec_helper'
require 'trema'

include Vnet::Constants::Openflow

describe Vnet::Openflow::Ports::Tunnel do
  describe "install" do
    it "creates tunnel specific flows" do
      datapath = MockDatapath.new(double, 10)
      port = Vnet::Openflow::Ports::Base.new(datapath, double(port_no: 10, name: 't-a'))
      port.extend(Vnet::Openflow::Ports::Tunnel)
      tunnel_manager = double(:tunnel_manager)
      tunnel_manager.should_receive(:add_port)
      datapath.should_receive(:tunnel_manager).and_return(tunnel_manager)

      port.install

      # pp datapath.added_flows

      expect(datapath.added_ovs_flows.size).to eq 0
      expect(datapath.added_flows.size).to eq 2

      expect(datapath.added_flows[0]).to eq Vnet::Openflow::Flow.create(
                                              TABLE_TUNNEL_PORTS,
                                              30,
                                              {:in_port => 10},
                                              nil,
                                              {:cookie => 10 | (COOKIE_PREFIX_PORT << COOKIE_PREFIX_SHIFT),
                                               :goto_table => TABLE_TUNNEL_NETWORK_IDS})
      expect(datapath.added_flows[1]).to eq Vnet::Openflow::Flow.create(
                                              TABLE_VIRTUAL_SRC,
                                              30,
                                              {:in_port => 10},
                                              nil,
                                              {:cookie => 10 | (COOKIE_PREFIX_PORT << COOKIE_PREFIX_SHIFT),
                                               :goto_table => TABLE_ROUTER_CLASSIFIER})
    end

  end

end
