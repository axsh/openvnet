# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class Tunnel < Vnet::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::Tunnel)
      object.to_hash
    end
  end

  class TunnelCollection < Vnet::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        Tunnel.generate(i)
      }
    end
  end
end
