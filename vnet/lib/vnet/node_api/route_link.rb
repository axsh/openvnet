# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class RouteLink < EventBase
    valid_update_fields []

    class << self
      private

      def create_with_transaction(options)
        options = options.dup

        topology_id = options.delete(:topology_id)

        transaction {
          handle_new_uuid(options)

          internal_create(options).tap { |model|
            next if model.nil?

            M::TopologyRouteLink.create(route_link_id: model.id, topology_id: topology_id) if topology_id
          }
        }
      end

      def dispatch_created_item_events(model)
        dispatch_event(ROUTER_CREATED_ITEM, model.to_hash)

        filter = { route_link_id: model.id }

        # 0009_topology
        TopologyRouteLink.dispatch_created_where(filter, model.created_at)
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
