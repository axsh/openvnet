# -*- coding: utf-8 -*-

require 'celluloid'

module Vnmgr::VNet::Openflow

  class NetworkManager
    attr_reader :datapath
    attr_reader :networks

    def initialize(dp)
      @datapath = dp
      @networks = {}
      @semaphore = Mutex.new
    end

    def network_by_uuid(network_uuid)
      network = nil

      @semaphore.synchronize {
        network = networks.find { |nw| nw[1].uuid == network_uuid }
      }

      return network[1] if network

      # Test data.
      network_map = Vnmgr::ModelWrappers::Network.find(network_uuid)

      # Simulate loading from db.
      sleep(0.1)
      
      case network_map.network_mode
      when 'physical'
        network = NetworkPhysical.new(self.datapath, network_map)
      when 'virtual'
        network = NetworkVirtual.new(self.datapath, network_map)
      else
        raise("Unknown network type.")
      end

      network_map.datapaths_on_subnet.each { |datapath_map|
        next if datapath_map.datapath_id == false # == self.datapath.foobar_id

        network.add_datapath_on_subnet(datapath_map, false)
      }

      @semaphore.synchronize {
        nw = networks.find { |nw| nw[1].uuid == network_uuid }

        if nw
          network = nw[1]
          next
        end

        @networks[network.network_id] = network
        network.install
      }

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
