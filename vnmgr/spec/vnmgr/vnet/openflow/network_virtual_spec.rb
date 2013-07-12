# -*- coding: utf-8 -*-
require 'spec_helper'
require 'ipaddr'
require 'trema'

include Vnmgr::VNet::Openflow::Constants

describe Vnmgr::VNet::Openflow::NetworkVirtual do
  describe "update_flows" do
    before(:all) do
      Fabricate(:vnet_1)
    end

    let(:vnet) do
      Vnmgr::VNet::Openflow::NetworkVirtual.new(datapath, Vnmgr::ModelWrappers::Network["nw-aaaaaaaa"])
    end

    let(:datapath) do
      MockDatapath.new(double(:ofc), ("a" * 16).to_i(16)).tap do |datapath|
        tunnel_manager = Vnmgr::VNet::Openflow::TunnelManager.new(datapath)

        cookie_manager = Vnmgr::VNet::Openflow::CookieManager.new
        cookie_manager.create_category(:tunnel, 0x6, 48)

        tunnel_port = double(:tunnel_port)
        tunnel_port.should_receive(:port_number).exactly(3).and_return(10)

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
        ((1 << METADATA_NETWORK_SHIFT) | 10),
        (METADATA_PORT_MASK | METADATA_NETWORK_MASK),
        TABLE_VIRTUAL_DST,
        (1 | (0x4 << 48)),
        ((1 << METADATA_NETWORK_SHIFT) | 0x0 | METADATA_FLAG_LOCAL),
        TABLE_VIRTUAL_DST
      ]
    end
  end
end
