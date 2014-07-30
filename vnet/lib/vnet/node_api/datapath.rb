# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class Datapath < EventBase
    class << self

      #
      # Internal methods:
      #

      private

      def dispatch_created_item_events(model)
        dispatch_event(DATAPATH_CREATED_ITEM, model.to_hash)
      end

      # DatapathNetwork and DatapathRouteLink events are not needed as
      # DatapathManager cleans up everything on the main deleted
      # event.
      def dispatch_deleted_item_events(model)
        dispatch_event(DATAPATH_DELETED_ITEM, id: model.id, node_id: model.node_id)

        default_filter = { datapath_id: model.id }
        tunnel_filter = Sequel.|({ src_datapath_id: model.id },
                                 { dst_datapath_id: model.id })

        ActiveInterface.dispatch_deleted_where(default_filter, model.deleted_at)
        InterfacePort.dispatch_deleted_where(default_filter, model.deleted_at)
        Tunnel.dispatch_deleted_where(tunnel_filter, model.deleted_at)
      end

    end
  end
end
