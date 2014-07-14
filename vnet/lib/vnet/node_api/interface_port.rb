# -*- coding: utf-8 -*-

module Vnet::NodeApi

  class InterfacePort < Base
    class << self
      def create(options)
        super.tap do |obj|
          # dispatch_event(INTERFACE_PORT_CREATED_ITEM, obj.values)
        end
      end

      def destroy(id)
        super.tap do |obj|
          # dispatch_event(INTERFACE_PORT_DELETED_ITEM, id: obj.id)
        end
      end
    end
  end

end
