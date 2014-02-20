# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class DhcpRange < Vnet::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::DhcpRange)
      object.to_hash.tap do |res|
        res[:range_begin] = object.range_begin_s
        res[:range_end] = object.range_end_s
      end
    end
  end

  class DhcpRangeCollection < Vnet::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        DhcpRange.generate(i)
      }
    end
  end
end
