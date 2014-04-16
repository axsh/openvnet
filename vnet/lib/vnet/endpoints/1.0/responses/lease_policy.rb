# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class LeasePolicy < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::LeasePolicy)
      object.to_hash
    end

    def self.lease_policy_network(object)
      argument_type_check(object,Vnet::ModelWrappers::LeasePolicy)
      {
        # TODO: currently just following example in responses/translation.rb,
        # so verify how this is used and if it is OK
        :uuid => object.uuid,
      }
    end

    def self.lease_policy_interface(object)
      argument_type_check(object,Vnet::ModelWrappers::LeasePolicy)
      {
        # TODO: currently just following example in responses/translation.rb,
        # so verify how this is used and if it is OK
        :uuid => object.uuid,
      }
    end
  end

  class LeasePolicyCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        LeasePolicy.generate(i)
      }
    end
  end
end
