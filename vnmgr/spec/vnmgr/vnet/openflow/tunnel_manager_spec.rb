# -*- coding: utf-8 -*-
require 'spec_helper'
require 'trema'

include Vnmgr::VNet::Openflow::Constants

describe Vnmgr::VNet::Openflow::TunnelManager do
  
  describe "create_all_tunnels" do
    before(:each) do
      (1..3).each { |i| Fabricate("datapath_#{i}") }
    end
  
    it "should create the entries in the tunnel table" do
      datapath = MockDatapath.new(double, ("a" * 16).to_i(16))
      tunnel_manager = Vnmgr::VNet::Openflow::TunnelManager.new(datapath)
      tunnel_manager.create_all_tunnels

      conf = Vnmgr::Configurations::Vna.conf
      db_tunnels = Vnmgr::Models::Datapath.find({:node_id => conf.node.id}).tunnels
      expect(db_tunnels.size).to eq 1
      expect(db_tunnels.first.dst_datapath.node_id).to eq "vna3"
      expect(db_tunnels.first.dst_datapath.dc_segment_id).to eq "2"

      expect(tunnel_manager.tunnels.size).to eq 1
      expect(tunnel_manager.tunnels.first[:uuid]).to eq db_tunnels.first.canonical_uuid
      expect(tunnel_manager.tunnels.first[:datapath_networks]).to eq []

      expect(datapath.added_tunnels.size).to eq 1
      expect(datapath.added_tunnels.first[:tunnel_name]).to eq db_tunnels.first.canonical_uuid
      expect(datapath.added_tunnels.first[:remote_ip]).to eq "192.168.2.2"
    end
  end

  describe "update_virtual_network" do
    before do
      Fabricate(:datapath_1, :dc_segment_id => 1)
      Fabricate(:datapath_2, :dc_segment_id => 2)
      Fabricate(:datapath_3, :dc_segment_id => 2)
    end

    let(:datapath) do
      MockDatapath.new(double, ("a" * 16).to_i(16)).tap do |datapath|
        datapath.switch = double(:cookie_manager => Vnmgr::VNet::Openflow::CookieManager.new)
      end
    end

    let(:tunnel_manager) do
      Vnmgr::VNet::Openflow::TunnelManager.new(datapath).tap do |tunnel_manager|
        tunnel_manager.create_all_tunnels
        tunnel_manager.insert(
         double(:broadcast_mac_addr => "bb:bb:bb:11:11:11", 
                :network_id => 1,
                :datapath_map => {:dpid => "0x#{'b' * 16}"}))
        tunnel_manager.insert(
         double(:broadcast_mac_addr => "bb:bb:bb:22:22:22", 
                :network_id => 2,
                :datapath_map => {:dpid => "0x#{'b' * 16}"}))
        tunnel_manager.insert(
          double(:broadcast_mac_addr => "cc:cc:cc:11:11:11", 
                 :network_id => 1,
                 :datapath_map => {:dpid => "0x#{'c' * 16}"}))
        datapath.added_flows.clear # This flows are not the subject
        datapath.switch.stub(:tunnel_ports).and_return(
          [double(port_name: datapath.added_tunnels[0][:tunnel_name], port_number: 9),
           double(port_name: datapath.added_tunnels[1][:tunnel_name], port_number: 10)])
      end
    end

    it "should add flood flow netwrok 1" do
      tunnel_manager.update_virtual_network(double(:network_number => 1))

      #pp datapath.added_flows
      expect(datapath.added_ovs_flows.size).to eq 0
      expect(datapath.added_flows.size).to eq 3

      expect(datapath.added_flows[0][:table_id]).to eq TABLE_METADATA_TUNNEL
      expect(datapath.added_flows[0][:priority]).to eq 1
      expect(datapath.added_flows[0][:match].metadata).to eq 1 << METADATA_NETWORK_SHIFT | OFPP_FLOOD
      expect(datapath.added_flows[0][:match].metadata_mask).to eq METADATA_PORT_MASK | METADATA_NETWORK_MASK
      expect(datapath.added_flows[0][:instructions][0].actions.size).to eq 4
      expect(datapath.added_flows[0][:instructions][0].actions[0].action_set[0]).to be_a Trema::Actions::TunnelId
      expect(datapath.added_flows[0][:instructions][0].actions[0].action_set[0].tunnel_id).to eq 1 | TUNNEL_FLAG
      expect(datapath.added_flows[0][:instructions][0].actions[1]).to be_a Trema::Actions::SendOutPort
      expect(datapath.added_flows[0][:instructions][0].actions[1].port).to eq 9
      expect(datapath.added_flows[0][:instructions][0].actions[2].action_set[0]).to be_a Trema::Actions::TunnelId
      expect(datapath.added_flows[0][:instructions][0].actions[2].action_set[0].tunnel_id).to eq 1 | TUNNEL_FLAG
      expect(datapath.added_flows[0][:instructions][0].actions[3]).to be_a Trema::Actions::SendOutPort
      expect(datapath.added_flows[0][:instructions][0].actions[3].port).to eq 10

      expect(datapath.added_flows[1][:table_id]).to eq TABLE_VIRTUAL_SRC
      expect(datapath.added_flows[1][:priority]).to eq 30
      expect(datapath.added_flows[1][:match].in_port).to eq 9
      expect(datapath.added_flows[1][:match].tunnel_id).to eq 1
      expect(datapath.added_flows[1][:match].tunnel_id_mask).to eq TUNNEL_NETWORK_MASK
      expect(datapath.added_flows[1][:instructions].size).to eq 1
      expect(datapath.added_flows[1][:instructions][0]).to be_a Trema::Instructions::GotoTable
      expect(datapath.added_flows[1][:instructions][0].table_id).to eq TABLE_VIRTUAL_DST

      expect(datapath.added_flows[2][:table_id]).to eq TABLE_VIRTUAL_SRC
      expect(datapath.added_flows[2][:priority]).to eq 30
      expect(datapath.added_flows[2][:match].in_port).to eq 10
      expect(datapath.added_flows[2][:match].tunnel_id).to eq 1
      expect(datapath.added_flows[2][:match].tunnel_id_mask).to eq TUNNEL_NETWORK_MASK
      expect(datapath.added_flows[2][:instructions].size).to eq 1
      expect(datapath.added_flows[2][:instructions][0]).to be_a Trema::Instructions::GotoTable
      expect(datapath.added_flows[2][:instructions][0].table_id).to eq TABLE_VIRTUAL_DST
    end

    it "should add flood flow for netwrok 2" do
      tunnel_manager.update_virtual_network(double(:network_number => 2))

      #pp datapath.added_flows
      expect(datapath.added_ovs_flows.size).to eq 0
      expect(datapath.added_flows.size).to eq 2

      expect(datapath.added_flows[0][:table_id]).to eq TABLE_METADATA_TUNNEL
      expect(datapath.added_flows[0][:priority]).to eq 1
      expect(datapath.added_flows[0][:match].metadata).to eq 2 << METADATA_NETWORK_SHIFT | OFPP_FLOOD
      expect(datapath.added_flows[0][:match].metadata_mask).to eq METADATA_PORT_MASK | METADATA_NETWORK_MASK
      expect(datapath.added_flows[0][:instructions][0].actions.size).to eq 2
      expect(datapath.added_flows[0][:instructions][0].actions[0].action_set[0]).to be_a Trema::Actions::TunnelId
      expect(datapath.added_flows[0][:instructions][0].actions[0].action_set[0].tunnel_id).to eq 2 | TUNNEL_FLAG
      expect(datapath.added_flows[0][:instructions][0].actions[1]).to be_a Trema::Actions::SendOutPort
      expect(datapath.added_flows[0][:instructions][0].actions[1].port).to eq 9

      expect(datapath.added_flows[1][:table_id]).to eq TABLE_VIRTUAL_SRC
      expect(datapath.added_flows[1][:priority]).to eq 30
      expect(datapath.added_flows[1][:match].in_port).to eq 9
      expect(datapath.added_flows[1][:match].tunnel_id).to eq 2
      expect(datapath.added_flows[1][:match].tunnel_id_mask).to eq TUNNEL_NETWORK_MASK
      expect(datapath.added_flows[1][:instructions].size).to eq 1
      expect(datapath.added_flows[1][:instructions][0]).to be_a Trema::Instructions::GotoTable
    end
  end
end
