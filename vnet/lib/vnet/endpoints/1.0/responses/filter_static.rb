# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class FilterStatic < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::FilterStatic)
      object.to_hash.tap { |res|
#        interface = object.batch.interface.commit  
#        res[:interface_uuid] = interface.uuid if interface
        res[:ipv4_address] = object.batch.ipv4_address_s.commit
      }
    end
  end

  class FilterStaticCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        FilterStatic.generate(i)
      }
    end
  end
end
