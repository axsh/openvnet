# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class RouteLink < EventBase
    class << self
      private

      def dispatch_created_item_events(model)
        # dispatch_event(ROUTE_LINK_CREATED_ITEM, model.to_hash)
      end

      def dispatch_deleted_item_events(model)
        # dispatch_event(ROUTE_LINK_DELETED_ITEM, id: model.id)

        # TODO: Event for all routes (?).
        filter = { route_link_id: model.id }

        Route.dispatch_deleted_where(filter, model.deleted_at)
        # DatapathRouteLink.dispatch_deleted_where(filter, model.deleted_at)
      end

    end
  end
end
