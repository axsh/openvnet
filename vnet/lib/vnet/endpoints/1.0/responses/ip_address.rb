# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class IpAddress < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::IpAddress)
      object.to_hash
    end
  end

  class IpAddressCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        IpAddress.generate(i)
      }
    end
  end
end
