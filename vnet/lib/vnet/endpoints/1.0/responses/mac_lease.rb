# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class MacLease < Vnet::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::MacLease)
      object.to_hash
    end
  end

  class MacLeaseCollection < Vnet::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        MacLease.generate(i)
      }
    end
  end
end
