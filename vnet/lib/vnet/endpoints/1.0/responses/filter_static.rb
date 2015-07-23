# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class FilterStatic < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      object.to_hash.tap { |res|
        interface = object.batch.interface.commit  
        res[:interface_uuid] = interface.uuid if interface
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
