# -*- coding: utf-8 -*-
require 'spec_helper'
require 'trema'

include Vnet::Constants::Openflow

describe Vnet::Openflow::TunnelManager do
  include_context :ofc_double

  describe "create_all_tunnels" do
    before(:each) do
      (1..3).each { |i| Fabricate("datapath_#{i}") }
    end

    let(:datapath) {
      MockDatapath.new(ofc, ("a" * 16).to_i(16)).tap { |dp|
        dp.create_mock_datapath_map
      }
    }

    subject {
      Vnet::Openflow::TunnelManager.new(datapath.dp_info).tap { |mgr|
        mgr.set_datapath_info(datapath.datapath_info)
      }
    }

    it "should create tunnels whose name is the same as datapath.uuid" do
      subject.create_all_tunnels
      expect(datapath.dp_info.added_tunnels[0][:tunnel_name]).to eq "t-test3"
    end

    it "should create the entries in the tunnel table" do
      subject.create_all_tunnels

      conf = Vnet::Configurations::Vna.conf
      db_tunnels = Vnet::Models::Datapath.find({:node_id => conf.node.id}).tunnels
      expect(db_tunnels.size).to eq 1
      expect(db_tunnels.first.dst_datapath.node_id).to eq "vna3"
      expect(db_tunnels.first.dst_datapath.dc_segment_id).to eq 2

      tunnel_infos = subject.select

      expect(tunnel_infos.size).to eq 1
      expect(tunnel_infos.first.uuid).to eq db_tunnels.first.canonical_uuid
      expect(tunnel_infos.first.datapath_networks_size).to eq 0

      expect(datapath.dp_info.added_tunnels.size).to eq 1
      expect(datapath.dp_info.added_tunnels.first[:remote_ip]).to eq "192.168.2.2"
    end

  end

  describe "update_virtual_network" do
    before do
      Fabricate(:datapath_1, :dc_segment_id => 1)
      Fabricate(:datapath_2, :dc_segment_id => 2)
      Fabricate(:datapath_3, :dc_segment_id => 2)
    end

    let(:datapath) do
      MockDatapath.new(ofc, ("a" * 16).to_i(16)).tap do |datapath|
        datapath.create_mock_datapath_map

        # datapath.switch = double(:cookie_manager => Vnet::Openflow::CookieManager.new)
        # datapath.switch.cookie_manager.create_category(:tunnel, 0x6, 48)
        #
        # datapath.cookie_manager = Vnet::Openflow::CookieManager.new
      end
    end

    let(:tunnel_manager) do
      Vnet::Openflow::TunnelManager.new(datapath.dp_info).tap do |tunnel_manager|
        tunnel_manager.set_datapath_info(datapath.datapath_info)

        tunnel_manager.create_all_tunnels
        tunnel_manager.insert(
          double(:id => 1,
                 :broadcast_mac_address => "bb:bb:bb:11:11:11",
                 :network_id => 1,
                 :datapath => double(:dpid => "0x#{'b' * 16}",
                                     :ipv4_address => IPAddr.new('1.1.1.1', Socket::AF_INET).to_i,
                                     :datapath_id => 1
                                     )))
        tunnel_manager.insert(
          double(:id => 2,
                 :broadcast_mac_address => "bb:bb:bb:22:22:22",
                 :network_id => 2,
                 :datapath => double(:dpid => "0x#{'b' * 16}",
                                     :ipv4_address => IPAddr.new('2.2.2.2', Socket::AF_INET).to_i,
                                     :datapath_id => 2
                                     )))
        tunnel_manager.insert(
          double(:id => 3,
                 :broadcast_mac_address => "cc:cc:cc:11:11:11",
                 :network_id => 1,
                 :datapath => double(:dpid => "0x#{'c' * 16}",
                                     :ipv4_address => IPAddr.new('1.1.1.2', Socket::AF_INET).to_i,
                                     :datapath_id => 3
                                     )))
      end
    end

    it "should only add broadcast mac addressess flows at start" do
      tunnel_manager

      flows = datapath.added_flows

      expect(datapath.added_ovs_flows.size).to eq 0
      expect(flows.size).to eq DATAPATH_IDLE_FLOWCOUNT

      # TunnelManager no longer creates the drop flows for broadcast
      # mac addresses, move.

      # expect(flows.size).to eq 6

      # expect(flows[0]).to eq Vnet::Openflow::Flow.create(
      #   TABLE_NETWORK_SRC_CLASSIFIER,
      #   90,
      #   {:eth_dst => Trema::Mac.new('bb:bb:bb:11:11:11')},
      #   nil,
      #   {:cookie => 1 | (COOKIE_PREFIX_DP_NETWORK << COOKIE_PREFIX_SHIFT)})

      # expect(flows[1]).to eq Vnet::Openflow::Flow.create(
      #   TABLE_NETWORK_DST_CLASSIFIER,
      #   90,
      #   {:eth_dst => Trema::Mac.new('bb:bb:bb:11:11:11')},
      #   nil,
      #   {:cookie => 1 | (COOKIE_PREFIX_DP_NETWORK << COOKIE_PREFIX_SHIFT)})

      # expect(flows[2]).to eq Vnet::Openflow::Flow.create(
      #   TABLE_NETWORK_SRC_CLASSIFIER,
      #   90,
      #   {:eth_dst => Trema::Mac.new('bb:bb:bb:22:22:22')},
      #   nil,
      #   {:cookie => 2 | (COOKIE_PREFIX_DP_NETWORK << COOKIE_PREFIX_SHIFT)})

      # expect(flows[3]).to eq Vnet::Openflow::Flow.create(
      #   TABLE_NETWORK_DST_CLASSIFIER,
      #   90,
      #   {:eth_dst => Trema::Mac.new('bb:bb:bb:22:22:22')},
      #   nil,
      #   {:cookie => 2 | (COOKIE_PREFIX_DP_NETWORK << COOKIE_PREFIX_SHIFT)})

      # expect(flows[4]).to eq Vnet::Openflow::Flow.create(
      #   TABLE_NETWORK_SRC_CLASSIFIER,
      #   90,
      #   {:eth_dst => Trema::Mac.new('cc:cc:cc:11:11:11')},
      #   nil,
      #   {:cookie => 3 | (COOKIE_PREFIX_DP_NETWORK << COOKIE_PREFIX_SHIFT)})

      # expect(flows[5]).to eq Vnet::Openflow::Flow.create(
      #   TABLE_NETWORK_DST_CLASSIFIER,
      #   90,
      #   {:eth_dst => Trema::Mac.new('cc:cc:cc:11:11:11')},
      #   nil,
      #   {:cookie => 3 | (COOKIE_PREFIX_DP_NETWORK << COOKIE_PREFIX_SHIFT)})
    end

    it "should add flood flow network 1" do
      tunnel_manager.update_item(event: :set_port_number,
                                 port_name: datapath.dp_info.added_tunnels[0][:tunnel_name],
                                 port_number: 9)
      tunnel_manager.update_item(event: :set_port_number,
                                 port_name: datapath.dp_info.added_tunnels[1][:tunnel_name],
                                 port_number: 10)

      datapath.added_flows.clear

      tunnel_manager.update(event: :update_network, network_id: 1)

      expect(datapath.added_ovs_flows.size).to eq 0
      expect(datapath.added_flows.size).to eq 1

      # expect(datapath.added_flows[0]).to eq Vnet::Openflow::Flow.create(
      #   TABLE_FLOOD_TUNNEL_PORTS,
      #   1,
      #   {:metadata => 1 | METADATA_TYPE_COLLECTION,
      #    :metadata_mask => METADATA_VALUE_MASK | METADATA_TYPE_MASK},
      #   [{:output => 9}, {:output => 10}],
      #   {:cookie => 1 | (COOKIE_PREFIX_COLLECTION << COOKIE_PREFIX_SHIFT)})

      expect(datapath.added_flows[0]).to eq Vnet::Openflow::Flow.create(
        TABLE_FLOOD_TUNNELS,
        1,
        {:metadata => 1 | METADATA_TYPE_NETWORK,
         :metadata_mask => METADATA_VALUE_MASK | METADATA_TYPE_MASK},
        [{:tunnel_id => 1 | TUNNEL_FLAG_MASK}, {:output => 9}, {:output => 10}],
        {:cookie => 1 | (COOKIE_PREFIX_NETWORK << COOKIE_PREFIX_SHIFT)})
    end

    it "should add flood flow for network 2" do
      tunnel_manager.update_item(event: :set_port_number,
                                 port_name: datapath.dp_info.added_tunnels[0][:tunnel_name],
                                 port_number: 9)
      tunnel_manager.update_item(event: :set_port_number,
                                 port_name: datapath.dp_info.added_tunnels[1][:tunnel_name],
                                 port_number: 10)

      datapath.added_flows.clear

      tunnel_manager.update(event: :update_network, network_id: 2)

      expect(datapath.added_ovs_flows.size).to eq 0
      expect(datapath.added_flows.size).to eq 1

      # expect(datapath.added_flows[0]).to eq Vnet::Openflow::Flow.create(
      #   TABLE_FLOOD_TUNNEL_PORTS,
      #   1,
      #   {:metadata => 2 | METADATA_TYPE_COLLECTION,
      #    :metadata_mask => METADATA_VALUE_MASK | METADATA_TYPE_MASK},
      #   [{:output => 9}],
      #   {:cookie => 2 | (COOKIE_PREFIX_COLLECTION << COOKIE_PREFIX_SHIFT)})

      expect(datapath.added_flows[0]).to eq Vnet::Openflow::Flow.create(
        TABLE_FLOOD_TUNNELS,
        1,
        {:metadata => 2 | METADATA_TYPE_NETWORK,
         :metadata_mask => METADATA_VALUE_MASK | METADATA_TYPE_MASK},
        [{:tunnel_id => 2 | TUNNEL_FLAG_MASK}, {:output => 9}],
        {:cookie => 2 | (COOKIE_PREFIX_NETWORK << COOKIE_PREFIX_SHIFT)})
    end

  end

  describe "remove_network_id_for_dpid" do
    before do
      # id=1, dpid="0x"+"a"*16
      Fabricate("datapath_1")
      # id=2, dpid="0x"+"c"*16
      Fabricate("datapath_3")
    end

    let(:ofctl) { double(:ofctl) }
    let(:datapath) {
      MockDatapath.new(ofc, ("a" * 16).to_i(16), ofctl).tap { |dp|
        dp.create_mock_datapath_map
      }
    }

    subject do
      Vnet::Openflow::TunnelManager.new(datapath.dp_info).tap do |tm|
        tm.set_datapath_info(datapath.datapath_info)

        tm.create_all_tunnels
        tm.insert(
          double(:id => 1,
                 :broadcast_mac_address => "bb:bb:bb:11:11:11",
                 :network_id => 1,
                 :datapath => double(:dpid => "0x#{'c' * 16}",
                                     :ipv4_address => IPAddr.new('1.1.1.1', Socket::AF_INET).to_i,
                                     :datapath_id => 1
                                     )))

      end
    end

    it "should delete tunnel when the network is deleted on the local datapath" do
      subject.remove_network_id_for_dpid(1, ("a" * 16).to_i(16))
      expect(datapath.dp_info.deleted_tunnels[0]).to eq "t-test3"
    end

    it "should delete tunnel when the network is deleted on the remote datapath" do
      subject.remove_network_id_for_dpid(1, ("c" * 16).to_i(16))
      expect(datapath.dp_info.deleted_tunnels[0]).to eq "t-test3"
    end
  end
end
