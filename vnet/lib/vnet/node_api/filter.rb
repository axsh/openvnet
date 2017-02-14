# -*- coding: utf-8 -*-

module Vnet::NodeApi

  class Filter < EventBase
    valid_update_fields [:ingress_passthrough, :egress_passthrough]

    class << self
      private

      def dispatch_created_item_events(model)
        dispatch_event(FILTER_CREATED_ITEM, model.to_hash)
      end

      def dispatch_updated_item_events(model, old_values)
        dispatch_event(FILTER_UPDATED, get_changed_hash(model, old_values.keys))
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(FILTER_DELETED_ITEM, id: model.id)

        # 0006_filters
        # filter_static: ignore, handled by main event
      end

    end
  end

end
