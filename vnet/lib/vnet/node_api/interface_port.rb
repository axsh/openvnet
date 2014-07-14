# -*- coding: utf-8 -*-

module Vnet::NodeApi

  class InterfacePort < Base
    class << self
      def create(options)
        super.tap do |model|
          dispatch_event(INTERFACE_PORT_CREATED_ITEM, model.to_hash)
        end
      end

      def destroy(id)
        super.tap do |model|
          dispatch_event(INTERFACE_PORT_DELETED_ITEM, model.to_hash)
        end
      end
    end
  end

end
