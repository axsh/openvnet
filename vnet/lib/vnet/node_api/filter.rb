# -*- coding: utf-8 -*-

module Vnet::NodeApi

  class Filter < EventBase
    class << self
      def update(uuid, options)
        options.each { |param|
          return unless param.first == "ingress_passthrough" || param.first == "egress_passthrough"
        }

        filter = transaction {
          model_class[uuid].tap do |model|
            model.update(options)
          end
        }.tap { |filter|
          dispatch_event(FILTER_UPDATED,
                         id: filter.id,
                         ingress_passthrough: filter.ingress_passthrough,
                         egress_passthrough: filter.egress_passthrough
                        )
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
