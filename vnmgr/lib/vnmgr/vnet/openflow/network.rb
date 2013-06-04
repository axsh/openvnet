# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  class Network
    include Constants

    attr_reader :datapath
    attr_reader :network_id
    attr_reader :network_number
    attr_reader :uuid
    attr_reader :ports
    attr_reader :datapath_of_bridge
    attr_reader :datapaths_on_subnet

    def initialize(dp, network_map)
      @datapath = dp
      @uuid = network_map.uuid
      @network_id = network_map.network_id
      @network_number = network_map.network_id
      @ports = {}
      @datapath_of_bridge = nil
      @datapaths_on_subnet = []
    end

    def add_port(port, should_update)
      raise("Port already added to a network.") if port.network || self.ports[port.port_number]

      self.ports[port.port_number] = port
      port.network = self

      update_flows if should_update
    end

    def del_port(port, should_update)
      deleted_port = self.ports.delete(port.port_number)
      update_flows if should_update

      raise("Port not added to this network.") if port.network != self || deleted_port.nil?

      port.network = nil
    end

    def set_datapath_of_bridge(datapath_map, should_update)
      @datapath_of_bridge = {
        :uuid => datapath_map.uuid,
        :display_name => datapath_map.display_name,
        :ipv4_address => datapath_map.ipv4_address,
        :datapath_id => datapath_map.datapath_id,
        :broadcast_mac_addr => datapath_map.broadcast_mac_addr,
      }

      # p "Setting the datapath of network: network:#{self.uuid} datapath:#{datapath.inspect}"

      update_flows if should_update
    end

    def add_datapath_on_subnet(datapath_map, should_update)
      datapath = {
        :uuid => datapath_map.uuid,
        :display_name => datapath_map.display_name,
        :ipv4_address => datapath_map.ipv4_address,
        :datapath_id => datapath_map.datapath_id,
        :broadcast_mac_addr => datapath_map.broadcast_mac_addr,
      }

      # p "Adding datapath to list of networks on the same subnet: network:#{self.uuid} datapath:#{datapath.inspect}"

      @datapaths_on_subnet << datapath
      update_flows if should_update
    end

  end

end
