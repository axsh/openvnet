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
end
