# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class NetworkService < EventBase
    class << self
      private

      def dispatch_created_item_events(model)
        dispatch_event(SERVICE_CREATED_ITEM, model.to_hash)
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(SERVICE_DELETED_ITEM, model.to_hash)

        filter = { network_id: model.id }

        # 0002_services
        # dns_services: :destroy
      end

    end
  end
end
