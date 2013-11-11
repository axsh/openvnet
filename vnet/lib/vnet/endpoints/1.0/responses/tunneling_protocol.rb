# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class TunnelingProtocol < Vnet::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object, Vnet::ModelWrappers::TunnelingProtocol)
      object.to_hash
    end
  end

  class TunnelingProtocolCollection < Vnet::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i| TunnelingProtocol.generate(i) }
    end
  end
end
