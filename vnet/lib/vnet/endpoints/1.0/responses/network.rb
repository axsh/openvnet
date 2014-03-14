# -*- coding: utf-8 -*-

require "ipaddress"

module Vnet::Endpoints::V10::Responses
  class Network < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(network)
      argument_type_check(network, Vnet::ModelWrappers::Network)
      res = network.to_hash

      res[:ipv4_network] = network.ipv4_network_s
      res
    end
  end

  class NetworkCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array, Array)
      array.map { |i| Network.generate(i) }
    end
  end
end
