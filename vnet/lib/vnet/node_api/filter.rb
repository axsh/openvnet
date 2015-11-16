# -*- coding: utf-8 -*-

module Vnet::NodeApi

  class Filter < EventBase
    class << self
      def update(uuid, options)
        filter = transaction {
          model_class[uuid].tap do |model|
            model.update(options)
          end
        }

        p filter.tap { |filter|
          dispatch_event(FILTER_UPDATED, model.to_hash)
        }
      end

      private

      def dispatch_created_item_events(model)
        dispatch_event(FILTER_CREATED_ITEM, model.to_hash)
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(FILTER_DELETED_ITEM, id: model.id)

        # 0001_origin
        # filter_static: ignore, handled by main event
      end

    end
  end

end
