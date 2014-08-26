# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class InterfacePort < EventBase
    class << self

      def create_with_uuid(options)
        model = create(options) || return

        interface = model.interface
        datapath = model.datapath

        model.to_hash.merge(interface_uuid: interface && interface.canonical_uuid,
                            datapath_uuid: datapath && datapath.canonical_uuid)
      end

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
