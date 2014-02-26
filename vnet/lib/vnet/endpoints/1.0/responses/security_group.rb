# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class SecurityGroup < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(secg)
      argument_type_check(secg, Vnet::ModelWrappers::SecurityGroup)
      secg.to_hash
    end
  end

  class SecurityGroupCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array, Array)
      array.map { |i| SecurityGroup.generate(i) }
    end
  end
end
