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
        if model.interface_id
          dispatch_event(INTERFACE_LEASED_MAC_ADDRESS, prepare_lease_event(model))
        end
      end

      # Need to include old values(?).
      def dispatch_updated_item_events(model, changed_keys)
        # dispatch_event(INTERFACE_SEGMENT_UPDATED_ITEM, get_changed_hash(model, changed_keys))
      end

      def dispatch_deleted_item_events(model)
        if model.interface_id
          dispatch_event(INTERFACE_RELEASED_MAC_ADDRESS, prepare_release_event(model))
        end

        filter = { mac_lease_id: model.id }

        # 0001_origin
        IpLease.dispatch_deleted_where(filter, model.deleted_at)
        # _mac_address: ignore
      end

      def prepare_lease_event(model)
        # model.to_hash.tap { |event_hash|
        #   event_hash[:mac_lease_id] = event_hash[:id]
        #   event_hash[:id] = event_hash[:interface_id]
        # }
        prepare_release_event(model)
      end

      def prepare_release_event(model)
        { id: model.interface_id,
          mac_lease_id: model.id
        }
      end

    end
  end
end
