# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class FilterStatic < EventBase
    class << self
      private

      def dispatch_created_item_events(model)
        model_hash = model.to_hash.merge(id: model.filter_id,
                                         static_id: model.id)

        dispatch_event(FILTER_ADDED_STATIC, model_hash)
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(FILTER_REMOVED_STATIC,
                       id: model.filter_id,
                       static_id: model.id)
      end

    end
  end
end
