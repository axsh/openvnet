# -*- coding: utf-8 -*-
require 'spec_helper'
require 'trema'

include Vnet::Constants::Openflow

describe Vnet::Openflow::TunnelManager do

  describe "update_virtual_network" do
    before do
      networks = (1..2).map { |i|
        Fabricate("pnet_public#{i}")
      }.values_at(0, 0, 1)

      (1..3).map { |i|
        dp_self = Fabricate("datapath_#{i}",
                            :dc_segment_id => [1, 2, 2][i-1])

        interface = Fabricate("interface_dp#{i}eth0",
                              owner_datapath_id: dp_self.id)

        mac_lease = Fabricate(:mac_lease,
                              interface: interface,
                              mac_address: Trema::Mac.new("08:00:27:00:01:0#{i}").value)

        ip_lease = Fabricate(:ip_lease,
                             mac_lease: mac_lease,
                             ipv4_address: dp_self.ipv4_address,
                             network_id: networks[i-1].id)

      }

      Fabricate(:datapath_network, datapath_id: 1, network_id: 1, interface_id: 1, broadcast_mac_address: 1)
      Fabricate(:datapath_network, datapath_id: 1, network_id: 2, interface_id: 1, broadcast_mac_address: 2)
      Fabricate(:datapath_network, datapath_id: 2, network_id: 1, interface_id: 2, broadcast_mac_address: 3)
      Fabricate(:datapath_network, datapath_id: 2, network_id: 2, interface_id: 2, broadcast_mac_address: 4)
      Fabricate(:datapath_network, datapath_id: 3, network_id: 1, interface_id: 3, broadcast_mac_address: 5)
    end

    let(:datapath) do
      MockDatapath.new(double, ("0x#{'a' * 16}").to_i(16)).tap do |datapath|
        datapath.create_mock_datapath_map

        # datapath.switch = double(:cookie_manager => Vnet::Openflow::CookieManager.new)
        # datapath.switch.cookie_manager.create_category(:tunnel, 0x6, 48)
        #
        # datapath.cookie_manager = Vnet::Openflow::CookieManager.new
      end
    end

    let(:tunnel_manager) do
      datapath.dp_info.tunnel_manager.tap do |tunnel_manager|
        tunnel_manager.prepare_network(1)
        tunnel_manager.prepare_network(2)
        tunnel_manager.insert(3)
        tunnel_manager.insert(4)
        tunnel_manager.insert(5)
      end
    end

    it "should only add broadcast mac addressess flows at start" do
      tunnel_manager

      flows = datapath.added_flows

      expect(datapath.added_ovs_flows.size).to eq 0
      expect(flows.size).to eq 8
    end

    it "should add flood flow network 1" do
      tunnel_manager.update_item(event: :set_port_number,
                                 uuid: datapath.dp_info.added_tunnels[0][:tunnel_name],
                                 port_number: 9)
      tunnel_manager.update_item(event: :set_port_number,
                                 uuid: datapath.dp_info.added_tunnels[1][:tunnel_name],
                                 port_number: 10)

      datapath.added_flows.clear

      tunnel_manager.update(event: :update_network, network_id: 1)

      expect(datapath.added_ovs_flows.size).to eq 0
      expect(datapath.added_flows.size).to eq 1

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
                                 uuid: datapath.dp_info.added_tunnels[0][:tunnel_name],
                                 port_number: 9)
      tunnel_manager.update_item(event: :set_port_number,
                                 uuid: datapath.dp_info.added_tunnels[1][:tunnel_name],
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
      #Fabricate("datapath_1", dc_segment_id: 1)
      #Fabricate("datapath_2", dc_segment_id: 2)

      # # id=1, dpid="0x"+"a"*16
      # Fabricate("datapath_1")
      # # id=2, dpid="0x"+"c"*16
      # Fabricate("datapath_3")

      networks = (1..2).map { |i|
        Fabricate("pnet_public#{i}")
      }.values_at(0, 0, 1)

      (1..3).map { |i|
        dp_self = Fabricate("datapath_#{i}",
                            :dc_segment_id => [1, 2, 2][i-1])

        interface = Fabricate("interface_dp#{i}eth0",
                              owner_datapath_id: dp_self.id)

        mac_lease = Fabricate(:mac_lease,
                              interface: interface,
                              mac_address: Trema::Mac.new("08:00:27:00:01:0#{i}").value)

        ip_lease = Fabricate(:ip_lease,
                             mac_lease: mac_lease,
                             ipv4_address: dp_self.ipv4_address,
                             network_id: networks[i-1].id)
      }

      Fabricate(:datapath_network, datapath_id: 1, network_id: 1, interface_id: 1, broadcast_mac_address: 1)
      Fabricate(:datapath_network, datapath_id: 2, network_id: 1, interface_id: 2, broadcast_mac_address: 2)
    end

    let(:ofctl) { double(:ofctl) }
    let(:datapath) {
      MockDatapath.new(double, ("0x#{'a' * 16}").to_i(16), ofctl).tap { |dp|
        dp.create_mock_datapath_map
      }
    }

    subject do
      datapath.dp_info.tunnel_manager.tap do |tm|
        tm.prepare_network(1)
        tm.insert(2)
      end
    end

    it "should delete tunnel when the network is deleted on the local datapath" do
      pending
      subject.remove_network(1)
      # TODO flood flow should be deleted
    end

    it "should delete tunnel when the network is deleted on the remote datapath" do
      subject.remove(2)
      sleep(0.001)
      expect(datapath.dp_info.deleted_tunnels[0]).to eq datapath.dp_info.added_tunnels[0][:tunnel_name]
    end
  end
end
