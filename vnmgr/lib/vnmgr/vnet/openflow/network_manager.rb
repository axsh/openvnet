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
      old_network = network_by_uuid_direct(network_uuid)
      return old_network if old_network

      network = nil
      network_map = Vnmgr::ModelWrappers::Network[network_uuid]

      dp_map = M::Datapath[:datapath_id => ("%#x" % @datapath.datapath_id)]
      
      raise("Could not find datapath id: %#x" % @datapath.datapath_id) unless dp_map

      dp_network_map = dp_map.batch.datapath_networks_dataset.where(:network_id => network_map.id).first.commit
      dpn_subnet_map = dp_map.batch.datapath_networks_on_subnet_dataset.where(:network_id => network_map.id).all.commit

      old_network = network_by_uuid_direct(network_uuid)
      return old_network if old_network

      case network_map.network_mode
      when 'physical'
        network = NetworkPhysical.new(self.datapath, network_map)
      when 'virtual'
        network = NetworkVirtual.new(self.datapath, network_map)
      else
        raise("Unknown network type.")
      end

      network.set_datapath_of_bridge(dp_map, dp_network_map, false)

      dpn_subnet_map.each { |dp_map| network.add_datapath_on_subnet(dp_map, false) }

      old_network = network_by_uuid_direct(network_uuid)
      return old_network if old_network

      @networks[network.network_id] = network

      network.install
      network.update_flows
      network
    end

    def network_by_uuid_direct(network_uuid)
      network = @networks.find { |nw| nw[1].uuid == network_uuid }
      network && network[1]
    end

    def update_all_flows
      @networks.dup.each { |key,network|
        p "Updating flows for: #{network.uuid}"
        network.update_flows
      }
    end

  end

end
