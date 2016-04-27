# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class ActiveNetwork < EventBase
    class << self
      private

      # Currently only supports very simple handling of race
      # conditions, etc.
      def create_with_transaction(options)
        network_id = options[:network_id]
        datapath_id = options[:datapath_id]

        transaction {
          model_class.where(network_id: network_id, datapath_id: datapath_id).destroy

          internal_create(options)
        }
      end

      def dispatch_created_item_events(model)
        dispatch_event(ACTIVE_NETWORK_CREATED_ITEM, model.to_hash)

        dispatch_event(TOPOLOGY_NETWORK_ACTIVATED,
                       id: [:network, model.network_id],
                       datapath_id: model.datapath_id,
                       )
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(ACTIVE_NETWORK_DELETED_ITEM, id: model.id)

        dispatch_event(TOPOLOGY_NETWORK_DEACTIVATED,
                       id: [:network, model.network_id],
                       datapath_id: model.datapath_id,
                       )
      end

    end
  end
end
