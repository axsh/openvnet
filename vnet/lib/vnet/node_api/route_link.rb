# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class RouteLink < EventBase
    valid_update_fields []

    class << self
      private

      def create_with_transaction(options)
        transaction {
          handle_new_uuid(options)

          mac_address_random_assign(options)
          internal_create(options)
        }
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
        # 0009_topology
        TopologyRouteLink.dispatch_deleted_where(filter, model.deleted_at)
        # 0011_assoc_interface
        InterfaceRouteLink.dispatch_deleted_where(filter, model.deleted_at)
      end

    end
  end
end
