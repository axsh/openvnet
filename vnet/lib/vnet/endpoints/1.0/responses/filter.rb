# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses

  class Filter < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::Filter)

      object.to_hash.tap do |res|
        interface = object.batch.interface.commit
        res[:interface_uuid] = interface.uuid if interface
        res.delete(:interface_id)
      end
    end

    def self.filter_statics(object)
      argument_type_check(object,Vnet::ModelWrappers::Filter)

      { uuid: object.uuid,
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

  class FilterStatic < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::FilterStatic)

      # TODO: Add filter uuid?
      { filter_id: object.filter_id,
        protocol: object.protocol,
        action: object.action,
        
        # TODO: Use local helper method.
        src_address: IPAddress::IPv4::parse_u32(object.ipv4_src_address).to_s,
        dst_address: IPAddress::IPv4::parse_u32(object.ipv4_dst_address).to_s,
        src_prefix: object.ipv4_src_prefix,
        dst_prefix: object.ipv4_dst_prefix
      }.tap { |result|
        result[:src_port] = object.port_src if object.port_src
        result[:dst_port] = object.port_dst if object.port_dst
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

