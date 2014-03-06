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

      host_addresses = [IPAddr.new("192.168.1.1").to_i,
                        IPAddr.new("192.168.1.2").to_i,
                        IPAddr.new("192.168.2.1").to_i]

      (1..3).map { |i|
        dp_self = Fabricate("datapath_#{i}")

        interface = Fabricate("interface_dp#{i}eth0",
                              owner_datapath_id: dp_self.id)

        mac_lease = Fabricate(:mac_lease,
                              interface: interface,
                              mac_address: Trema::Mac.new("08:00:27:00:01:0#{i}").value)

        ip_lease = Fabricate(:ip_lease,
                             mac_lease: mac_lease,
                             ipv4_address: host_addresses[i-1],
                             network_id: networks[i-1].id)
      }

      Fabricate(:datapath_network, datapath_id: 1, network_id: 1, interface_id: 1, broadcast_mac_address: 1)
      Fabricate(:datapath_network, datapath_id: 1, network_id: 2, interface_id: 1, broadcast_mac_address: 2)
      Fabricate(:datapath_network, datapath_id: 2, network_id: 1, interface_id: 2, broadcast_mac_address: 3)
      Fabricate(:datapath_network, datapath_id: 2, network_id: 2, interface_id: 2, broadcast_mac_address: 4)
      Fabricate(:datapath_network, datapath_id: 3, network_id: 1, interface_id: 3, broadcast_mac_address: 5)
    end

    let(:datapath) do
      MockDatapath.new(double, ("0x#{'a' * 16}").to_i(16)).tap do |dp|
        dp.create_mock_datapath_map

        # dp.switch = double(:cookie_manager => Vnet::Openflow::CookieManager.new)
        # dp.switch.cookie_manager.create_category(:tunnel, 0x6, 48)
        #
        # dp.cookie_manager = Vnet::Openflow::CookieManager.new

        if1_id = dp.dp_info.interface_manager.retrieve(uuid: 'if-dp2eth0').id
        if2_id = dp.dp_info.interface_manager.retrieve(uuid: 'if-dp3eth0').id
        if3_id = dp.dp_info.interface_manager.retrieve(uuid: 'if-dp1eth0').id
        sleep(0.1)

        dp.added_flows.clear
      end
    end

    # TODO: Make some tests fail when the tunnel port is loaded but
    # not the host port.
    let(:host_port_1) do
      dp_info = datapath.dp_info

      dp_info.tunnel_manager.update(event: :updated_interface,
                                    interface_event: :set_host_port_number,
                                    interface_id: dp_info.interface_manager.retrieve(uuid: 'if-dp1eth0').id,
                                    port_number: 1)
    end

    let(:host_datapath_networks) do
      [[1, 1, 1, 1],
       [2, 1, 2, 1]].each { |index, datapath_id, network_id, interface_id|
        datapath.dp_info.tunnel_manager.update(event: :added_host_datapath_network,
                                               dpn: {
                                                 id: index,
                                                 datapath_id: datapath_id,
                                                 network_id: network_id,
                                                 interface_id: interface_id,
                                                 mac_address: index,
                                                 active: true
                                               })
      }
    end

    let(:remote_datapath_networks_1) do
      [[3, 2, 1, 2],
       [5, 3, 1, 3]].each { |index, datapath_id, network_id, interface_id|
        datapath.dp_info.tunnel_manager.update(event: :added_remote_datapath_network,
                                               dpn: {
                                                 id: index,
                                                 datapath_id: datapath_id,
                                                 network_id: network_id,
                                                 interface_id: interface_id,
                                                 mac_address: index,
                                                 active: true
                                               })
      }
    end

    let(:remote_datapath_networks_2) do
      [[4, 2, 2, 2]].each { |index, datapath_id, network_id, interface_id|
        datapath.dp_info.tunnel_manager.update(event: :added_remote_datapath_network,
                                               dpn: {
                                                 id: index,
                                                 datapath_id: datapath_id,
                                                 network_id: network_id,
                                                 interface_id: interface_id,
                                                 mac_address: index,
                                                 active: true
                                               })
      }
    end

    let(:tunnel_manager) do
      datapath.dp_info.tunnel_manager.tap do |tunnel_manager|
      end
    end

    it "should only add broadcast mac addressess flows at start" do
      pending "Current dpn/dprl and tunnel creation method does not fit this test."

      host_datapath_networks
      # host_port_1

      added_flows = datapath.added_flows.uniq
      # added_flows.each { |flow| pp flow.inspect }

      datapath.added_tunnels.each { |tunnel| pp tunnel.inspect }

      expect(datapath.added_ovs_flows.size).to eq 0
      expect(added_flows.size).to eq 7
    end

    it "should add flood flow network 1" do
      host_datapath_networks
      remote_datapath_networks_1

      datapath.added_flows.clear

      host_port_1

      sleep(0.1)

      added_flows = datapath.added_flows.uniq
      # added_flows.each { |flow| pp flow.inspect }

      expect(datapath.dp_info.added_tunnels.size).to eq 1
      expect(datapath.added_ovs_flows.size).to eq 0
      expect(added_flows.size).to eq 2

      # expect(added_flows[0]).to eq Vnet::Openflow::Flow.create(
      #   TABLE_FLOOD_SEGMENT,
      #   1,
      #   {:metadata => 1 | METADATA_TYPE_NETWORK,
      #    :metadata_mask => METADATA_VALUE_MASK | METADATA_TYPE_MASK},
      #   [],
      #   {:goto_table => TABLE_FLOOD_TUNNELS,
      #    :cookie => 1 | (COOKIE_PREFIX_NETWORK << COOKIE_PREFIX_SHIFT)})
      # expect(added_flows[1]).to eq Vnet::Openflow::Flow.create(
      #   TABLE_FLOOD_TUNNELS,
      #   1,
      #   {:metadata => 1 | METADATA_TYPE_NETWORK,
      #    :metadata_mask => METADATA_VALUE_MASK | METADATA_TYPE_MASK},
      #   [{:tunnel_id => 1 | TUNNEL_FLAG_MASK}, {:output => 9}],
      #   {:cookie => 1 | (COOKIE_PREFIX_NETWORK << COOKIE_PREFIX_SHIFT)})
    end

    it "should add flood flow for network 2" do
      host_datapath_networks
      remote_datapath_networks_2

      sleep(0.1)

      datapath.added_flows.clear

      tunnel_manager.update(event: :set_tunnel_port_number,
                            port_name: datapath.dp_info.added_tunnels[0][:tunnel_name],
                            port_number: 9)

      sleep(0.1)

      added_flows = datapath.added_flows.uniq
      # added_flows.each { |flow| pp flow.inspect }

      expect(datapath.added_ovs_flows.size).to eq 0
      expect(added_flows.size).to eq 1

      # expect(added_flows[0]).to eq Vnet::Openflow::Flow.create(
      #   TABLE_FLOOD_SEGMENT,
      #   1,
      #   {:metadata => 1 | METADATA_TYPE_NETWORK,
      #    :metadata_mask => METADATA_VALUE_MASK | METADATA_TYPE_MASK},
      #   [],
      #   {:cookie => 1 | (COOKIE_PREFIX_NETWORK << COOKIE_PREFIX_SHIFT)})
      expect(added_flows[0]).to eq Vnet::Openflow::Flow.create(
        TABLE_FLOOD_TUNNELS,
        1,
        {:metadata => 1 | METADATA_TYPE_NETWORK,
         :metadata_mask => METADATA_VALUE_MASK | METADATA_TYPE_MASK},
        [{:tunnel_id => 1 | TUNNEL_FLAG_MASK}, {:output => 9}],
        {:goto_table => TABLE_FLOOD_SEGMENT,
         :cookie => 1 | (COOKIE_PREFIX_NETWORK << COOKIE_PREFIX_SHIFT)})
    end

  end

  describe "remove_network_id_for_dpid" do
    before do
      networks = (1..2).map { |i|
        Fabricate("pnet_public#{i}")
      }.values_at(0, 0, 1)

      host_addresses = [IPAddr.new("192.168.1.1").to_i,
                        IPAddr.new("192.168.1.2").to_i,
                        IPAddr.new("192.168.2.1").to_i]

      (1..3).map { |i|
        dp_self = Fabricate("datapath_#{i}")

        interface = Fabricate("interface_dp#{i}eth0",
                              owner_datapath_id: dp_self.id)

        mac_lease = Fabricate(:mac_lease,
                              interface: interface,
                              mac_address: Trema::Mac.new("08:00:27:00:01:0#{i}").value)

        ip_lease = Fabricate(:ip_lease,
                             mac_lease: mac_lease,
                             ipv4_address: host_addresses[i-1],
                             network_id: networks[i-1].id)
      }

      Fabricate(:datapath_network, datapath_id: 1, network_id: 1, interface_id: 1, broadcast_mac_address: 1)
      Fabricate(:datapath_network, datapath_id: 2, network_id: 1, interface_id: 2, broadcast_mac_address: 2)
    end

    let(:ofctl) { double(:ofctl) }
    let(:datapath) {
      MockDatapath.new(double, ("0x#{'a' * 16}").to_i(16), ofctl).tap { |dp|
        dp_info = dp.dp_info

        dp.create_mock_datapath_map

        dp_info.interface_manager.retrieve(uuid: 'if-dp2eth0')
        dp_info.interface_manager.retrieve(uuid: 'if-dp3eth0')
        dp_info.interface_manager.retrieve(uuid: 'if-dp1eth0')
      }
    }

    subject do
      datapath.dp_info.tunnel_manager.tap do |tm|
        dp_info = datapath.dp_info

        if_dp1eth0 = dp_info.interface_manager.retrieve(uuid: 'if-dp1eth0')
        expect(if_dp1eth0)

        dp_info.tunnel_manager.update(event: :updated_interface,
                                      interface_event: :set_host_port_number,
                                      interface_id: if_dp1eth0.id,
                                      port_number: 1)
        [[1, 1, 1, 1, :added_host_datapath_network],
         [2, 2, 1, 2, :removed_remote_datapath_network],
         [3, 2, 1, 2, :added_remote_datapath_network],
         #[4, 2, 2, 2, :added_remote_datapath_network],
         [5, 3, 1, 3, :added_remote_datapath_network],
        ].each { |index, datapath_id, network_id, interface_id, event|
          dp_info.tunnel_manager.update(event: event,
                                        dpn: {
                                          id: index,
                                          datapath_id: datapath_id,
                                          network_id: network_id,
                                          interface_id: interface_id,
                                          mac_address: index,
                                          active: true
                                        })
        }

        sleep(0.1)
        datapath.added_flows.clear
        datapath.deleted_flows.clear
      end
    end

    it "should delete tunnel when the network is deleted on the local datapath" do
      subject

      added_flows = datapath.added_flows.uniq
      # added_flows.each { |flow| pp flow.inspect }
      deleted_flows = datapath.deleted_flows
      # deleted_flows.each { |flow| pp flow.inspect }

      [[1, 1, 1, 1, :removed_host_datapath_network],
      ].each { |index, datapath_id, network_id, interface_id, event|
        datapath.dp_info.tunnel_manager.update(event: event,
                                               dpn: {
                                                 id: index,
                                                 datapath_id: datapath_id,
                                                 network_id: network_id,
                                                 interface_id: interface_id,
                                                 mac_address: index,
                                                 active: false
                                               })
      }

      sleep(0.1)

      added_flows = datapath.added_flows.uniq
      # added_flows.each { |flow| pp flow.inspect }
      deleted_flows = datapath.deleted_flows
      # deleted_flows.each { |flow| pp flow.inspect }

      expect(datapath.added_ovs_flows.size).to eq 0
      expect(added_flows.size).to eq 0
      expect(deleted_flows.size).to eq 2

      # pp datapath.dp_info.deleted_tunnels.inspect

      expect(datapath.dp_info.deleted_tunnels.size).to eq 1
      expect(datapath.dp_info.deleted_tunnels[0]).to eq datapath.dp_info.added_tunnels[0][:tunnel_name]
    end

    it "should delete tunnel when the network is deleted on the remote datapath" do
      subject

      [[3, 2, 1, 2, :removed_remote_datapath_network],
      ].each { |index, datapath_id, network_id, interface_id, event|
        datapath.dp_info.tunnel_manager.update(event: event,
                                               dpn: {
                                                 id: index,
                                                 datapath_id: datapath_id,
                                                 network_id: network_id,
                                                 interface_id: interface_id,
                                                 mac_address: index,
                                                 active: false
                                               })
      }

      sleep(0.1)
      datapath.added_flows.clear
      datapath.deleted_flows.clear

      [[5, 3, 1, 3, :removed_remote_datapath_network],
      ].each { |index, datapath_id, network_id, interface_id, event|
        datapath.dp_info.tunnel_manager.update(event: event,
                                               dpn: {
                                                 id: index,
                                                 datapath_id: datapath_id,
                                                 network_id: network_id,
                                                 interface_id: interface_id,
                                                 mac_address: index,
                                                 active: false
                                               })
      }

      sleep(0.1)

      added_flows = datapath.added_flows.uniq
      # added_flows.each { |flow| pp flow.inspect }
      deleted_flows = datapath.deleted_flows
      # deleted_flows.each { |flow| pp flow.inspect }

      expect(datapath.added_ovs_flows.size).to eq 0
      expect(added_flows.size).to eq 0
      expect(deleted_flows.size).to eq 2

      # pp datapath.dp_info.deleted_tunnels.inspect

      expect(datapath.dp_info.deleted_tunnels[0]).to eq datapath.dp_info.added_tunnels[0][:tunnel_name]
    end
  end
end
