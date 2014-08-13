# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class RouteLink < EventBase
    class << self
      private

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
