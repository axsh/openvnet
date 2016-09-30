# -*- coding: utf-8 -*-
module Vnet::NodeApi
  class MacLease < EventBase
    class << self

      # TODO: Get rid of this.
      def update(uuid, options)
        deleted_mac_address = false

        mac_lease = transaction do
          model_class[uuid].tap do |model|
            deleted_mac_address = true if options[:mac_address]
            model.set(options)
            model.save_changes
            model
          end
        end

        if deleted_mac_address
          dispatch_deleted_item_events(mac_lease)
          dispatch_created_item_events(mac_lease)
        end

        mac_lease
      end

      #
      # Internal methods:
      #

      private

      def dispatch_created_item_events(model)
        dispatch_event(INTERFACE_LEASED_MAC_ADDRESS,
                       id: model.interface_id,
                       mac_lease_id: model.id,
                       mac_address: model.mac_address)
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(INTERFACE_RELEASED_MAC_ADDRESS,
                       id: model.interface_id,
                       mac_lease_id: model.id)

        filter = { mac_lease_id: model.id }

        # 0001_origin
        IpLease.dispatch_deleted_where(filter, model.deleted_at)
        # _mac_address: ignore
      end

    end
  end
end
