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
      network_map = case network_uuid
                    when 'nw-public'
                      { :id => 2, :uuid => 'nw-public', :type => 'physical',  :ipv4 => '192.168.60.0', :ipv4_prefix => 24 }
                    when 'nw-vnet'
                      { :id => 3, :uuid => 'nw-vnet', :type => 'virtual', :ipv4 => '10.0.0.0', :ipv4_prefix => 24 }
                    else
                      raise("Unknown network uuid.")
                    end
      # Simulate loading from db.
      sleep(0.1)
      
      network = Network.new(self.datapath, network_map[:id], network_map[:uuid])

      @networks[network.network_id] = network

      network.install
      network
    end

  end

end
