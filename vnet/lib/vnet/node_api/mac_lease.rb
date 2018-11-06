# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class MacLease < EventBase
    valid_update_fields [:interface_id]

    class << self

      def dispatch_deleted_for_segment(segment_id, deleted_at)
        filter_date = ['deleted_at >= ? || deleted_at = NULL',
                       (deleted_at || Time.now) - 3]

        # I wanted to use a dataset here like I did in NodeApi::IpLease to keep it all SQL.
        # Unfortunately this didn't quite work out due to how the mac_address plugin is written.
        mac_address_ids = M::MacAddress.with_deleted.where(segment_id: segment_id).map { |ma| ma.id }

        M::MacLease.with_deleted.where(mac_address_id: mac_address_ids).where(*filter_date).each { |lease|
          dispatch_deleted_item_events(lease)
        }
      end

      #
      # Internal methods:
      #

      private

      def create_with_transaction(options)
        transaction {
          handle_new_uuid(options)

          options.delete(:mac_range_group_id).tap { |mrg_id|
            next if options[:mac_address] || mrg_id.nil?
            options[:_mac_address] = create_address_from_mrg(mrg_id)
          }

          internal_create(options).tap { |model|
            next if model.nil?
            InterfaceSegment.update_assoc(model.interface_id, model.segment_id)
          }
        }
      end

      def create_address_from_mrg(mrg_id)
        M::MacRangeGroup[id: mrg_id].tap { |mrg|
          if mrg.nil?
            raise ArgumentError, 'Unknown MacRangeGroup id'
          end

          return mrg.address_random
        }
      end

      def destroy_with_transaction(filter)
        transaction {
          internal_destroy(model_class[filter]).tap { |model|
            next if model.nil?
            InterfaceSegment.update_assoc(model.interface_id, model.segment_id)
          }
        }
      end

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
