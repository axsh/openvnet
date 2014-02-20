# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class SecurityGroup < Vnet::Endpoints::ResponseGenerator
    def self.generate(secg)
      argument_type_check(secg, Vnet::ModelWrappers::SecurityGroup)
      secg.to_hash
    end

    def self.interfaces(secg)
      argument_type_check(secg, Vnet::ModelWrappers::SecurityGroup)
      {
        :uuid => secg.uuid,
        :interfaces => secg.batch.interfaces.commit.map { |i| i.uuid }
      }
    end
  end

  class SecurityGroupCollection < Vnet::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array, Array)
      array.map { |i| SecurityGroup.generate(i) }
    end
  end
end
