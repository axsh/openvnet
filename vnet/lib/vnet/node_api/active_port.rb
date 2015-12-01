# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class ActivePort < EventBase
    class << self
      private

      # Currently only supports very simple handling of race
      # conditions, etc.
      def create_with_transaction(options)
        port_name = options[:port_name]
        port_number = options[:port_number]
        datapath_id = options[:datapath_id]

        transaction {
          self.destroy(datapath_id: datapath_id, port_name: port_name)
          self.destroy(datapath_id: datapath_id, port_number: port_number)

          internal_create(options)
        }
      end

      def dispatch_created_item_events(model)
        dispatch_event(ACTIVE_PORT_CREATED_ITEM, model.to_hash)
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(ACTIVE_PORT_DELETED_ITEM, id: model.id)
      end

    end
  end
end
