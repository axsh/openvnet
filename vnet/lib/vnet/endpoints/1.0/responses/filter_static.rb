# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class FilterStatic < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::FilterStatic)

      res = {
        ipv4_address: object.batch.ipv4_dst_address_s.commit,
        ipv4_prefix: object.ipv4_dst_prefix,
        port_number: object.port_dst,
        protocol: object.protocol,
        passthrough: object.passthrough
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
