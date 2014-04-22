# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class IpRange < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::IpRange)
      object.to_hash
    end

    def self.ip_ranges_ranges(object)
      argument_type_check(object,Vnet::ModelWrappers::IpRange)
      {
        # TODO: based on translate.rb. Do more here?
        :uuid => object.uuid,
      }
    end
  end

  class IpRangeCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        IpRange.generate(i)
      }
    end
  end
end
