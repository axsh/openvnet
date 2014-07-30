# -*- coding: utf-8 -*-

module Vnet::NodeApi

  class InterfacePort < EventBase
    class << self

      #
      # Internal methods:
      #

      private

      def dispatch_created_item_events(model)
        dispatch_event(INTERFACE_PORT_CREATED_ITEM, model.to_hash)
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(INTERFACE_PORT_DELETED_ITEM, id: model.id)
      end

    end
  end

end
