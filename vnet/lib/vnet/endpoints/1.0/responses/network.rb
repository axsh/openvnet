# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class Network < Vnet::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::Network)
      object.to_hash
    end
  end

  class NetworkCollection < Vnet::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        Network.generate(i)
      }
    end
  end
end
