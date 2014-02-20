# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class DnsService < Vnet::Endpoints::ResponseGenerator
    def self.generate(model)
      argument_type_check(model, Vnet::ModelWrappers::DnsService)
      model.network_service_uuid = model.network_service.uuid
      model.to_hash
    end

    def self.dns_records(model)
      argument_type_check(model, Vnet::ModelWrappers::DnsService)
      DnsRecordCollection.generate(model.batch.dns_records.commit)
    end
  end

  class DnsServiceCollection < Vnet::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array, Array)
      array.map { |i| DnsService.generate(i) }
    end
  end
end
