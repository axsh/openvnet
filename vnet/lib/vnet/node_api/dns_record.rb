# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class DnsRecord < Base
    class << self
      def create(options)
        super.tap do |model|
          dispatch_event(
            ADDED_DNS_RECORD,
            id: model.dns_service.network_service_id,
            dns_record_id: model.id
          )
        end
      end

      def destroy(uuid)
        super.tap do |model|
          dispatch_event(
            REMOVED_DNS_RECORD,
            id: model.dns_service.network_service_id,
            dns_record_id: model.id
          )
        end
      end
    end
  end
end
