# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class MacAddress < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::MacAddress)
      object.to_hash
    end
  end

  class MacAddressCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        MacAddress.generate(i)
      }
    end
  end
end
