# -*- coding: utf-8 -*-
require 'spec_helper'
require 'ipaddr'
require 'trema'

include Vnet::Constants::Openflow

describe Vnet::Openflow::NetworkVirtual do

  OF = Vnet::Openflow
  MW = Vnet::ModelWrappers

  describe "update_flows" do
    before { Fabricate(:vnet_1) }   
    let(:vnet) { OF::NetworkVirtual.new(datapath, MW::Network["nw-aaaaaaaa"]) }

    let(:datapath) do
      MockDatapath.new(double(:ofc), ("a" * 16).to_i(16)).tap do |datapath|
        tunnel_manager = OF::TunnelManager.new(datapath)

        cookie_manager = OF::CookieManager.new
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

    it "should apply cookies containing network id and tunnel port number to each flow" do
      vnet.update_flows

      expect(datapath.added_ovs_flows[0]).to eq "table=#{TABLE_VIRTUAL_SRC},priority=81,cookie=0x%x,in_port=%d,arp,metadata=0x%x/0x%x,actions=learn\\(table=%d,cookie=0x%x,idle_timeout=36000,priority=35,metadata:0x%x,NXM_OF_ETH_DST\\[\\]=NXM_OF_ETH_SRC\\[\\],load:NXM_NX_TUN_ID\\[\\]\\-\\>NXM_NX_TUN_ID\\[\\],output:NXM_OF_IN_PORT\\[\\]\\),goto_table:%d" % [ 
        ((1 << COOKIE_NETWORK_SHIFT) | 10 | (0x6 << 48)),
        10,
        ((1 << METADATA_NETWORK_SHIFT) | METADATA_FLAG_REMOTE),
        (METADATA_NETWORK_MASK | METADATA_FLAG_LOCAL | METADATA_FLAG_REMOTE),
        TABLE_VIRTUAL_DST,
        ((1 << COOKIE_NETWORK_SHIFT) | 10 | (0x6 << 48)),
        ((1 << METADATA_NETWORK_SHIFT) | 0x0 | METADATA_FLAG_LOCAL),
        TABLE_ROUTER_ENTRY
      ]
    end
  end

  describe "uninstall" do
    before { Fabricate(:vnet_1) }   

    let(:vnet) { OF::NetworkVirtual.new(datapath, MW::Network["nw-aaaaaaaa"]) }
    let(:datapath) do
      MockDatapath.new(double(:ofc), ("a" * 16).to_i(16)).tap do |datapath|
        switch = double(:switch)

        tunnel_port = double(:tunnel_port)
        tunnel_port.should_receive(:port_number).exactly(1).and_return(10)

        cookie_manager = OF::CookieManager.new
        cookie_manager.create_category(:tunnel, 0x6, 48)

        switch.should_receive(:cookie_manager).and_return(cookie_manager)
        switch.should_receive(:tunnel_ports).and_return([tunnel_port])
        switch.should_receive(:tunnel_manager).and_return(OF::TunnelManager.new(datapath))

        datapath.switch = switch
      end
    end

    context "delete_tunnel_flows" do
      it "should delete tunnel flows" do
        vnet.delete_tunnel_flows
        expect(datapath.added_cookie[0]).to eq ((1 << COOKIE_NETWORK_SHIFT) | 10 | (0x6 << 48))
      end
    end

    context "notify_to_delete_tunnel_port" do
      it "should notify all vna to delete tunnel port" do
      end
    end
  end
end
