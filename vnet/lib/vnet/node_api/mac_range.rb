# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class MacRangeGroup < EventBase
    valid_update_fields [:allocation_type]

    class << self
      private

      def dispatch_created_item_events(model)
        dispatch_event(MAC_RANGE_GROUP_CREATED_ITEM, model.to_hash)
      end

      def dispatch_updated_item_events(model, old_values)
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(MAC_RANGE_GROUP_DELETED_ITEM, id: model.id)

        filter = { mac_range_id: model.id }

        # 0018_topology_lease
        TopologyMacRangeGroup.dispatch_created_where(filter, model.created_at)
      end

    end
  end

  class MacRange < EventBase
    valid_update_fields []

    class << self
      private

      def dispatch_created_item_events(model)
        # dispatch_event(MAC_RANGE_CREATED_ITEM, model.to_hash)

        # TODO: Dispatch to topologies.
      end

      def dispatch_updated_item_events(model, old_values)
      end

      def dispatch_deleted_item_events(model)
        # dispatch_event(MAC_RANGE_DELETED_ITEM, id: model.id)
      end

    end
  end
end
