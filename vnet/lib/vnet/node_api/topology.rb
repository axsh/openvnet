# -*- coding: utf-8 -*-

module Vnet::NodeApi

  class Topology < EventBase
    valid_update_fields []

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

  class TopologyDatapath < AssocBase
    valid_update_fields []

    class << self
      private

      def parent_id_type
        :topology_id
      end

      def assoc_id_type
        :datapath_id
      end

      def event_created_name
        TOPOLOGY_ADDED_DATAPATH
      end

      def event_deleted_name
        TOPOLOGY_REMOVED_DATAPATH
      end

    end
  end

  class TopologyNetwork < AssocBase
    valid_update_fields []

    class << self
      private

      def parent_id_type
        :topology_id
      end

      def assoc_id_type
        :network_id
      end

      def event_created_name
        TOPOLOGY_ADDED_NETWORK
      end

      def event_deleted_name
        TOPOLOGY_REMOVED_NETWORK
      end

    end
  end

  class TopologySegment < AssocBase
    valid_update_fields []

    class << self
      private

      def parent_id_type
        :topology_id
      end

      def assoc_id_type
        :segment_id
      end

      def event_created_name
        TOPOLOGY_ADDED_SEGMENT
      end

      def event_deleted_name
        TOPOLOGY_REMOVED_SEGMENT
      end

    end
  end

  class TopologyRouteLink < AssocBase
    valid_update_fields []

    class << self
      private

      def parent_id_type
        :topology_id
      end

      def assoc_id_type
        :route_link_id
      end

      def event_created_name
        TOPOLOGY_ADDED_ROUTE_LINK
      end

      def event_deleted_name
        TOPOLOGY_REMOVED_ROUTE_LINK
      end

    end
  end

end
