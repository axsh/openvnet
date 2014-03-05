# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class LeasePolicy < Vnet::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::LeasePolicy)
      object.to_hash
    end
  end

  class LeasePolicyCollection < Vnet::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        LeasePolicy.generate(i)
      }
    end
  end
end
