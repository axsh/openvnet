# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class ActiveRouteLink < EventBase
    class << self
      private

      # Currently only supports very simple handling of race
      # conditions, etc.
      def create_with_transaction(options)
        route_link_id = options[:route_link_id]
        datapath_id = options[:datapath_id]

        transaction {
          model_class.where(route_link_id: route_link_id,
                            datapath_id: datapath_id).destroy

          internal_create(options)
        }
      end

      def dispatch_created_item_events(model)
        dispatch_event(ACTIVE_ROUTE_LINK_CREATED_ITEM, model.to_hash)

        dispatch_event(TOPOLOGY_ROUTE_LINK_ACTIVATED,
                       id: [:route_link, model.route_link_id],
                       datapath_id: model.datapath_id,
                       )
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(ACTIVE_ROUTE_LINK_DELETED_ITEM, id: model.id)

        dispatch_event(TOPOLOGY_ROUTE_LINK_DEACTIVATED,
                       id: [:route_link, model.route_link_id],
                       datapath_id: model.datapath_id,
                       )
      end

    end
  end
end
