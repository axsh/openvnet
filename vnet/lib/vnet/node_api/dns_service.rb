# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class DnsService < LegacyBase
    valid_update_fields [:public_dns]

    class << self
      def create(options)
        super.tap do |model|
          dispatch_event(
            SERVICE_ADDED_DNS,
            id: model.network_service_id,
            dns_service_id: model.id
          )
        end
      end

      def destroy(uuid)
        super.tap do |model|
          dispatch_event(
            SERVICE_REMOVED_DNS,
            id: model.network_service_id,
            dns_service_id: model.id
          )
        end
      end

      private

      def dispatch_updated_item_events(model, old_values)
        dispatch_event(SERVICE_UPDATED_DNS, id: model.network_service_id, dns_service_id: model.id)
      end

    end
  end
end
