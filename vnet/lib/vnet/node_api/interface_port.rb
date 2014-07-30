# -*- coding: utf-8 -*-

module Vnet::NodeApi

  class InterfacePort < EventBase
    class << self

      #
      # Internal methods:
      #

      private

      def created_item_event
        INTERFACE_PORT_CREATED_ITEM
      end

      def deleted_item_event
        INTERFACE_PORT_DELETED_ITEM
      end

    end
  end

end
