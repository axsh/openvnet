# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class MacLease < EventBase
    valid_update_fields [:interface_id]

    class << self

      #
      # Internal methods:
      #

      private

      def dispatch_created_item_events(model)
        filter = {
          id: model.interface_id,
          segment_id: model. segment_id,
          mac_lease_id: model.id,
          mac_address: model.mac_address
        }

        dispatch_event(INTERFACE_LEASED_MAC_ADDRESS, filter)

        # dispatch_event(INTERFACE_SEGMENT_CREATED_ITEM, model.to_hash)
      end

      # Need to include old values(?).
      def dispatch_updated_item_events(model, changed_keys)
        # dispatch_event(INTERFACE_SEGMENT_UPDATED_ITEM, get_changed_hash(model, changed_keys))
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
