# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class Datapath < EventBase
    class << self
      private

      def dispatch_created_item_events(model)
        dispatch_event(DATAPATH_CREATED_ITEM, model.to_hash)
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(DATAPATH_DELETED_ITEM, id: model.id, node_id: model.node_id)

        default_filter = { datapath_id: model.id }
        tunnel_filter = Sequel.|({ src_datapath_id: model.id },
                                 { dst_datapath_id: model.id })

        # 0001_origin
        ActiveInterface.dispatch_deleted_where(default_filter, model.deleted_at)
        ActiveNetwork.dispatch_deleted_where(default_filter, model.deleted_at)
        # datapath_network: ignore, handled by main event
        # datapath_route_link: ignore, handled by main event
        InterfacePort.dispatch_deleted_where(default_filter, model.deleted_at)
        Tunnel.dispatch_deleted_where(tunnel_filter, model.deleted_at)
        # 0009_topology
        TopologyDatapath.dispatch_deleted_where(default_filter, model.deleted_at)
      end

    end
  end
end
