# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class DnsService < Base
    class << self
      def create(options)
        super.tap do |model|
          dispatch_event(
            ADDED_DNS_SERVICE,
            id: model.network_service_id,
            dns_service_id: model.id
          )
        end
      end

      def update(uuid, options)
        options = options.dup
        transaction {
          model_class[uuid].tap do |model|
            return unless model
            model.update(options)
          end
        }.tap do |model|
          dispatch_event(
            UPDATED_DNS_SERVICE,
            id: model.network_service_id,
            dns_service_id: model.id
          )
        end
      end


      def destroy(uuid)
        super.tap do |model|
          dispatch_event(
            REMOVED_DNS_SERVICE,
            id: model.network_service_id,
            dns_service_id: model.id
          )
        end
      end
    end
  end
end
