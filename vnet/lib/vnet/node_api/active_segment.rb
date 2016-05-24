# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class ActiveSegment < EventBase
    class << self
      private

      # Currently only supports very simple handling of race
      # conditions, etc.
      def create_with_transaction(options)
        segment_id = options[:segment_id]
        datapath_id = options[:datapath_id]

        transaction {
          model_class.where(segment_id: segment_id, datapath_id: datapath_id).destroy

          internal_create(options)
        }
      end

      def dispatch_created_item_events(model)
        dispatch_event(ACTIVE_SEGMENT_CREATED_ITEM, model.to_hash)

        # dispatch_event(TOPOLOGY_SEGMENT_ACTIVATED,
        #                id: [:segment, model.segment_id],
        #                datapath_id: model.datapath_id
        #               )
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(ACTIVE_SEGMENT_DELETED_ITEM, id: model.id)

        # dispatch_event(TOPOLOGY_SEGMENT_DEACTIVATED,
        #                id: [:segment, model.segment_id],
        #                datapath_id: model.datapath_id
        #               )
      end

    end
  end
end
