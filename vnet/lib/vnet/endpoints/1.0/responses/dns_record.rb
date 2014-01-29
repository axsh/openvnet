# -*- coding: utf-8 -*-

require "ipaddress"

module Vnet::Endpoints::V10::Responses
  class DnsRecord < Vnet::Endpoints::ResponseGenerator
    def self.generate(model)
      argument_type_check(model, Vnet::ModelWrappers::DnsRecord)
      model.to_hash
    end
  end

  class DnsRecordCollection < Vnet::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array, Array)
      array.map { |i| DnsRecord.generate(i) }
    end
  end
end
