# -*- coding: utf-8 -*-

require "ipaddress"

module Vnet::Endpoints::V10::Responses
  class Network < Vnet::Endpoints::ResponseGenerator
    def self.generate(network)
      argument_type_check(network, Vnet::ModelWrappers::Network)
      res = network.to_hash

      res[:ipv4_network] = network.ipv4_network_s
      res
    end

    def self.dhcp_ranges(network)
      argument_type_check(network, Vnet::ModelWrappers::Network)
      {
        :uuid => network.uuid,
        :dhcp_ranges => DhcpRangeCollection.generate(
          network.batch.dhcp_ranges.commit
        )
      }
    end
  end

  class NetworkCollection < Vnet::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array, Array)
      array.map { |i| Network.generate(i) }
    end
  end
end
