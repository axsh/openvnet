# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class RouteLink < EventBase
    class << self
      private

      def create_with_transaction(options)
        mac_address = options[:mac_address]
        mac_group_uuid = Vnet::Configurations::Common.conf.datapath_mac_group
        transaction do
          mac_address_random_assign(options)
          model = internal_create(options)
        end
      end

      def dispatch_created_item_events(model)
        dispatch_event(ROUTER_CREATED_ITEM, model.to_hash)
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(ROUTER_DELETED_ITEM, id: model.id)

        filter = { route_link_id: model.id }

        # 0001_origin
        DatapathRouteLink.dispatch_deleted_where(filter, model.deleted_at)
        Route.dispatch_deleted_where(filter, model.deleted_at)
        # translation_static_addresses: :destroy,
      end

    end
  end
end
