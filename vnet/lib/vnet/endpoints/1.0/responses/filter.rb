# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class Filter < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::Filter)
      object.to_hash.tap do |res|
        interface = object.batch.interface.commit  
        res[:interface_uuid] = interface.uuid if interface
      end
    end

    def self.static(object)
        argument_type_check(object,Vnet::ModelWrappers::Filter)
      {
        :uuid => object.uuid,
      }
    end
      
  end

  class FilterCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        Filter.generate(i)
      }
    end
  end
end
