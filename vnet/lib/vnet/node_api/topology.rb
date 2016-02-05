# -*- coding: utf-8 -*-

module Vnet::NodeApi

  class Topology < EventBase
    class << self
      private

      def dispatch_created_item_events(model)
        dispatch_event(TOPOLOGY_CREATED_ITEM, model.to_hash)
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(TOPOLOGY_DELETED_ITEM, id: model.id)

        # no dependencies
      end

    end
  end

  class TopologyDatapath < EventBase
    class << self
      private

      def dispatch_created_item_events(model)
        model_hash = model.to_hash.merge(id: model.topology_id,
                                         datapath_id: model.id)

        dispatch_event(TOPOLOGY_ADDED_DATAPATH, model_hash)
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(TOPOLOGY_REMOVED_DATAPATH,
                       id: model.topology_id,
                       datapath_id: model.id)
      end

    end
  end

  class TopologyNetwork < EventBase
    class << self
      private

      def dispatch_created_item_events(model)
        model_hash = model.to_hash.merge(id: model.topology_id,
                                         network_id: model.id)

        dispatch_event(TOPOLOGY_ADDED_NETWORK, model_hash)
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(TOPOLOGY_REMOVED_NETWORK,
                       id: model.topology_id,
                       network_id: model.id)
      end
    end
  end

  class TopologyRouteLink < EventBase
    class << self
      private

      def dispatch_created_item_events(model)
        model_hash = model.to_hash.merge(id: model.topology_id,
                                         route_link_id: model.id)

        dispatch_event(TOPOLOGY_ADDED_ROUTE_LINK, model_hash)
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(TOPOLOGY_REMOVED_ROUTE_LINK,
                       id: model.topology_id,
                       route_link_id: model.id)
      end
    end
  end

end
