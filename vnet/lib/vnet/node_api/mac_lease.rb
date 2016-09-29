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

      def dispatch_updated_item_events(model, old_values)
        if old_values.has_key?(:interface_id) && old_values[:interface_id]
          dispatch_event(INTERFACE_RELEASED_MAC_ADDRESS, prepare_release_event(model.to_hash.merge(old_values)))
        end

        if old_values.has_key?(:interface_id) && model[:interface_id]
          dispatch_event(INTERFACE_LEASED_MAC_ADDRESS, prepare_lease_event(model))
        end
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

      def prepare_lease_event(model_map)
        # model_map.to_hash.tap { |event_hash|
        #   event_hash[:mac_lease_id] = event_hash[:id]
        #   event_hash[:id] = event_hash[:interface_id]
        # }
        prepare_release_event(model_map)
      end

      def prepare_release_event(model_map)
        { id: model_map[:interface_id],
          mac_lease_id: model_map[:id]
        }
      end

    end
  end
end
