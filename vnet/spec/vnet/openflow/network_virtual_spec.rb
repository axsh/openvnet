# -*- coding: utf-8 -*-
require 'spec_helper'
require 'ipaddr'
require 'trema'

include Vnet::Constants::Openflow

describe Vnet::Openflow::NetworkVirtual do

  describe "update_flows" do
    before { Fabricate(:vnet_1) }
    let(:vnet) { Vnet::Openflow::NetworkVirtual.new(datapath, Vnet::ModelWrappers::Network["nw-aaaaaaaa"]) }

    let(:datapath) do
      MockDatapath.new(double(:ofc), ("a" * 16).to_i(16)).tap do |datapath|
        tunnel_manager = Vnet::Openflow::TunnelManager.new(datapath)

        cookie_manager = Vnet::Openflow::CookieManager.new
        cookie_manager.create_category(:tunnel, 0x6, 48)

        tunnel_port = double(:tunnel_port)
        tunnel_port.should_receive(:port_number).exactly(2).and_return(10)

        switch = double(:switch)
        switch.should_receive(:cookie_manager).and_return(cookie_manager)
        switch.should_receive(:eth_ports).and_return([])
        switch.should_receive(:tunnel_ports).and_return([tunnel_port])
        switch.should_receive(:tunnel_manager).and_return(tunnel_manager)

        datapath.switch = switch
      end
    end
  end
end
