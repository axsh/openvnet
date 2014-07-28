# -*- coding: utf-8 -*-
require 'spec_helper'
require 'trema'

include Vnet::Constants::Openflow

describe Vnet::Core::TunnelManager do

  use_mock_event_handler

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

        interface = Fabricate("interface_dp#{i}eth0")
        Fabricate(:interface_port_eth0,
                  interface_id: interface.id,
                  datapath_id: dp_self.id)

        if i != 1
          active_interface = Fabricate(:active_interface,
                                       interface_id: interface.id,
                                       datapath_id: dp_self.id,
                                       singular: 1,
                                       port_name: 'eth0')
        end

        mac_lease = Fabricate(:mac_lease,
                              interface: interface,
                              mac_address: Trema::Mac.new("08:00:27:00:01:0#{i}").value)

        ip_lease = Fabricate(:ip_lease,
                             mac_lease: mac_lease,
                             ipv4_address: host_addresses[i-1],
                             network_id: networks[i-1].id)
      }

      Fabricate(:datapath_network, datapath_id: 1, network_id: 1, interface_id: 1, ip_lease_id: 1, broadcast_mac_address: 1)
      Fabricate(:datapath_network, datapath_id: 1, network_id: 2, interface_id: 1, ip_lease_id: 1, broadcast_mac_address: 2)
      Fabricate(:datapath_network, datapath_id: 2, network_id: 1, interface_id: 2, ip_lease_id: 2, broadcast_mac_address: 3)
      Fabricate(:datapath_network, datapath_id: 2, network_id: 2, interface_id: 2, ip_lease_id: 2, broadcast_mac_address: 4)
      Fabricate(:datapath_network, datapath_id: 3, network_id: 1, interface_id: 3, ip_lease_id: 3, broadcast_mac_address: 5)
    end

    let(:datapath) do
      MockDatapath.new(double, ("0x#{'a' * 16}").to_i(16)).tap do |dp|
        dp.create_mock_datapath_map

        if2_id = dp.dp_info.active_interface_manager.retrieve(interface_id: 2)[:interface_id]
        if3_id = dp.dp_info.active_interface_manager.retrieve(interface_id: 3)[:interface_id]
        if1_id = dp.dp_info.interface_manager.load_local_interface(1).id

        sleep(0.3)

        dp.dp_info.added_flows.clear
      end
    end

    let(:dp_info) do
      datapath.dp_info
    end

    # TODO: Make some tests fail when the tunnel port is loaded but
    # not the host port.
    let(:host_port_1) do
      dp_info = datapath.dp_info

      dp_info.tunnel_manager.update(event: :updated_interface,
                                    interface_event: :set_host_port_number,
                                    interface_id: 1,
                                    port_number: 1)
    end

    let(:host_datapath_networks) do
      [[1, 1, 1, 1, 1],
       [2, 1, 2, 1, 1]].each { |index, datapath_id, network_id, interface_id, ip_lease_id|
        datapath.dp_info.tunnel_manager.publish('added_host_datapath_network',
                                                id: :datapath_network,
                                                dp_obj: {
                                                  id: index,
                                                  datapath_id: datapath_id,
                                                  network_id: network_id,
                                                  interface_id: interface_id,
                                                  mac_address: index,
                                                  ip_lease_id: ip_lease_id,
                                                  active: true
                                                })
      }
    end

    let(:remote_datapath_networks_1) do
      [[3, 2, 1, 2, 2],
       [5, 3, 1, 3, 3]].each { |index, datapath_id, network_id, interface_id, ip_lease_id|
        datapath.dp_info.tunnel_manager.publish('added_remote_datapath_network',
                                                id: :datapath_network,
                                                dp_obj: {
                                                  id: index,
                                                  datapath_id: datapath_id,
                                                  network_id: network_id,
                                                  interface_id: interface_id,
                                                  ip_lease_id: ip_lease_id,
                                                  mac_address: index,
                                                  active: true
                                                })
      }
    end

    let(:remote_datapath_networks_2) do
      [[4, 2, 2, 2, 2]].each { |index, datapath_id, network_id, interface_id, ip_lease_id|
        datapath.dp_info.tunnel_manager.publish('added_remote_datapath_network',
                                                id: :datapath_network,
                                                dp_obj: {
                                                  id: index,
                                                  datapath_id: datapath_id,
                                                  network_id: network_id,
                                                  interface_id: interface_id,
                                                  ip_lease_id: ip_lease_id,
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

      added_flows = dp_info.added_flows.uniq
      # added_flows.each { |flow| pp flow.inspect }

      dp_info.added_tunnels.each { |tunnel| pp tunnel.inspect }

      expect(dp_info.added_ovs_flows.size).to eq 0
      expect(added_flows.size).to eq 7
    end

    it "should add flood flow network 1" do
      host_datapath_networks
      remote_datapath_networks_1

      sleep(0.3)

      dp_info.added_flows.clear

      host_port_1

      sleep(0.3)

      added_flows = dp_info.added_flows.uniq
      added_flows.each { |flow| pp flow.inspect }

      expect(datapath.dp_info.added_tunnels.size).to eq 1
      expect(dp_info.added_ovs_flows.size).to eq 0
      expect(added_flows.size).to eq 1

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

      sleep(0.3)

      dp_info.added_flows.clear

      tunnel_manager.update(event: :set_tunnel_port_number,
                            port_name: datapath.dp_info.added_tunnels[0][:tunnel_name],
                            port_number: 9)

      sleep(0.3)

      added_flows = dp_info.added_flows.uniq
      # added_flows.each { |flow| pp flow.inspect }

      expect(dp_info.added_ovs_flows.size).to eq 0
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

        interface = Fabricate("interface_dp#{i}eth0")
        Fabricate(:interface_port_eth0,
                  interface_id: interface.id,
                  datapath_id: dp_self.id)

        mac_lease = Fabricate(:mac_lease,
                              interface: interface,
                              mac_address: Trema::Mac.new("08:00:27:00:01:0#{i}").value)

        ip_lease = Fabricate(:ip_lease,
                             mac_lease: mac_lease,
                             ipv4_address: host_addresses[i-1],
                             network_id: networks[i-1].id)

        if i != 1
          active_interface = Fabricate(:active_interface,
                                       interface_id: interface.id,
                                       datapath_id: dp_self.id,
                                       singular: 1,
                                       port_name: 'eth0')
        end
      }

      Fabricate(:datapath_network, datapath_id: 1, network_id: 1, interface_id: 1, ip_lease_id: 1, broadcast_mac_address: 1)
      Fabricate(:datapath_network, datapath_id: 2, network_id: 1, interface_id: 2, ip_lease_id: 2, broadcast_mac_address: 2)
    end

    let(:ofctl) { double(:ofctl) }
    let(:datapath) {
      MockDatapath.new(double, ("0x#{'a' * 16}").to_i(16), ofctl).tap { |dp|
        dp_info = dp.dp_info

        dp.create_mock_datapath_map

        dp_info.active_interface_manager.retrieve(interface_id: 2)[:interface_id]
        dp_info.active_interface_manager.retrieve(interface_id: 3)[:interface_id]
        dp_info.interface_manager.load_local_interface(1).id
      }
    }

    let(:dp_info) do
      datapath.dp_info
    end

    subject do
      datapath.dp_info.tunnel_manager.tap do |tm|
        dp_info = datapath.dp_info

        if_dp1eth0 = dp_info.interface_manager.detect(uuid: 'if-dp1eth0')
        expect(if_dp1eth0)

        dp_info.tunnel_manager.update(event: :updated_interface,
                                      interface_event: :set_host_port_number,
                                      interface_id: if_dp1eth0.id,
                                      port_number: 1)
        [[1, 1, 1, 1, 1, 'added_host_datapath_network'],
         [2, 2, 1, 2, 2, 'removed_remote_datapath_network'],
         [3, 2, 1, 2, 2, 'added_remote_datapath_network'],
         #[4, 2, 2, 2, 'added_remote_datapath_network'],
         [5, 3, 1, 3, 3, 'added_remote_datapath_network'],
        ].each { |index, datapath_id, network_id, interface_id, ip_lease_id, event|
          dp_info.tunnel_manager.publish(event,
                                         id: :datapath_network,
                                         dp_obj: {
                                           id: index,
                                           datapath_id: datapath_id,
                                           network_id: network_id,
                                           interface_id: interface_id,
                                           mac_address: index,
                                           ip_lease_id: ip_lease_id,
                                           active: true
                                         })
        }

        sleep(0.3)
        dp_info.added_flows.clear
        dp_info.deleted_flows.clear
      end
    end

    it "should delete tunnel when the network is deleted on the local datapath" do
      subject

      added_flows = dp_info.added_flows.uniq
      deleted_flows = dp_info.deleted_flows
      # added_flows.each { |flow| pp flow.inspect }
      # deleted_flows.each { |flow| pp flow.inspect }

      [[1, 1, 1, 1, 1, 'removed_host_datapath_network'],
      ].each { |index, datapath_id, network_id, interface_id, ip_lease_id, event|
        datapath.dp_info.tunnel_manager.publish(event,
                                                id: :datapath_network,
                                                dp_obj: {
                                                  id: index,
                                                  datapath_id: datapath_id,
                                                  network_id: network_id,
                                                  interface_id: interface_id,
                                                  mac_address: index,
                                                  ip_lease_id: ip_lease_id,
                                                  active: false
                                                })
      }

      sleep(0.3)

      added_flows = dp_info.added_flows.uniq
      deleted_flows = dp_info.deleted_flows
      # added_flows.each { |flow| pp flow.inspect }
      # deleted_flows.each { |flow| pp flow.inspect }

      expect(dp_info.added_ovs_flows.size).to eq 0
      # expect(added_flows.size).to eq 0
      expect(deleted_flows.size).to eq 2

      # pp datapath.dp_info.deleted_tunnels.inspect

      expect(datapath.dp_info.deleted_tunnels.size).to eq 1
      expect(datapath.dp_info.deleted_tunnels[0]).to eq datapath.dp_info.added_tunnels[0][:tunnel_name]
    end

    it "should delete tunnel when the network is deleted on the remote datapath" do
      subject

      [[3, 2, 1, 2, 2, 'removed_remote_datapath_network'],
      ].each { |index, datapath_id, network_id, interface_id, ip_lease_id, event|
        datapath.dp_info.tunnel_manager.publish(event,
                                                id: :datapath_network,
                                                dp_obj: {
                                                  id: index,
                                                  datapath_id: datapath_id,
                                                  network_id: network_id,
                                                  interface_id: interface_id,
                                                  mac_address: index,
                                                  ip_lease_id: ip_lease_id,
                                                  active: false
                                                })
      }

      sleep(0.3)
      dp_info.added_flows.clear
      dp_info.deleted_flows.clear

      [[5, 3, 1, 3, 3, 'removed_remote_datapath_network'],
      ].each { |index, datapath_id, network_id, interface_id, ip_lease_id, event|
        datapath.dp_info.tunnel_manager.publish(event,
                                                id: :datapath_network,
                                                dp_obj: {
                                                  id: index,
                                                  datapath_id: datapath_id,
                                                  network_id: network_id,
                                                  interface_id: interface_id,
                                                  mac_address: index,
                                                  ip_lease_id: ip_lease_id,
                                                  active: false
                                                })
      }

      sleep(0.3)

      added_flows = dp_info.added_flows.uniq
      deleted_flows = dp_info.deleted_flows
      added_flows.each { |flow| pp flow.inspect }
      deleted_flows.each { |flow| pp flow.inspect }

      expect(dp_info.added_ovs_flows.size).to eq 0
      # expect(added_flows.size).to eq 0
      # expect(deleted_flows.size).to eq 2

      # pp datapath.dp_info.deleted_tunnels.inspect

      expect(datapath.dp_info.deleted_tunnels[0]).to eq datapath.dp_info.added_tunnels[0][:tunnel_name]
    end
  end
end
