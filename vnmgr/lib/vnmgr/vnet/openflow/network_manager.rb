# -*- coding: utf-8 -*-

require 'celluloid'

module Vnmgr::VNet::Openflow

  class NetworkManager
    attr_reader :datapath

    def initialize(dp)
      @datapath = dp
      @networks = {}
      @semaphore = Mutex.new
    end

    def network_by_uuid(network_uuid)
      old_network = @networks.find { |nw| nw[1].uuid == network_uuid }
      return old_network[1] if old_network

      network = nil
      network_map = Vnmgr::ModelWrappers::Network[network_uuid]

      datapath_map = M::Datapath[:datapath_id => ("%#x" % @datapath.datapath_id)]
      datapaths_on_subnet_map = datapath_map.batch.datapaths_on_subnet.commit

      old_network = @networks.find { |nw| nw[1].uuid == network_uuid }
      return old_network[1] if old_network

      case network_map.network_mode
      when 'physical'
        network = NetworkPhysical.new(self.datapath, network_map)
      when 'virtual'
        network = NetworkVirtual.new(self.datapath, network_map)
      else
        raise("Unknown network type.")
      end

      network.set_datapath_of_bridge(datapath_map, false)
      datapaths_on_subnet_map.each { |dp_map| network.add_datapath_on_subnet(dp_map, false) }

      old_network = @networks.find { |nw| nw[1].uuid == network_uuid }
      return old_network[1] if old_network

      @networks[network.network_id] = network

      network.install
      network.update_flows
      network
    end

    def update_all_flows
      @networks.each { |key,network|
        p "Updating flows for: #{network.uuid}"
        network.update_flows
      }
    end

  end

end
