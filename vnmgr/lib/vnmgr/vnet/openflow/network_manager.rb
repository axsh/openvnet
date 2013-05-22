# -*- coding: utf-8 -*-

require 'celluloid'

module Vnmgr::VNet::Openflow

  class NetworkManager
    attr_reader :datapath
    attr_reader :networks

    def initialize(dp)
      @datapath = dp
      @networks = {}
    end

    def network_by_uuid(network_uuid)
      network = networks.find { |nw| nw[1].uuid == network_uuid }
      return network[1] if network

      # Test data.
      network_map = Vnmgr::ModelWrappers::NetworkWrapper.find(network_uuid)

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

      @networks[network.network_id] = network

      network.install
      network
    end

  end

end
