# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class FilterStatic < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::FilterStatic)
      object.to_hash.tap { |res|
        # Separation between source port and destination port is implemented
        # in the model but the code to handle it isn't quite there yet. Hide the
        # model in the API response for now.
        res[:port_number] = res[:port_src]
        res.delete(:port_src)
        res.delete(:port_dst)

        # Same as the above for ipv4 address.
        res[:ipv4_address] = object.batch.ipv4_src_address_s.commit
        res.delete(:ipv4_src_address)
        res.delete(:ipv4_dst_address)
        res.delete(:ipv4_dst_prefix)
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
