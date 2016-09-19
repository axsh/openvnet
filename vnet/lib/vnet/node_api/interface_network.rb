# -*- coding: utf-8 -*-

# This association does not allow direct creation/destrucion of
# entries.
#
# Instead it automatically manages the lifetime of the association
# depending on if there is an association or not, and allows for
# persistency if 'static' is true.

module Vnet::NodeApi
  class InterfaceNetwork < EventBase
    class << self

      def create(options)
        raise NotImplementedError
      end

      def destroy(filter)
        raise NotImplementedError
      end

      # TODO: Must be called within a transaction.
      def leased(interface_id, network_id)
        transaction {
          get_model(interface_id, network_id).tap { |model|
            return model if model
          }

          create_with_transaction(interface_id: interface_id, network_id: network_id)
        }.tap { |model|
          next if model.nil?
          dispatch_created_item_events(model)
        }
      end

      # TODO: Must be called within a transaction.
      def released(interface_id, network_id)
        transaction {
          get_model(interface_id, network_id).tap { |model|
            return if model.nil? || model.static
            internal_destroy(model) if leases_empty?(interface_id, network_id)
          }
        }.tap { |model|
          next if model.nil?
          dispatch_deleted_item_events(model)
        }
      end

      def set_static(interface_id, network_id)
        transaction {
          get_model(interface_id, network_id).tap { |model|
            return update_model_no_validate(model, static: true) if model
          }

          create_with_transaction(interface_id: interface_id, network_id: network_id, static: true)

        }.tap { |model|
          next if model.nil?
          dispatch_created_item_events(model)
        }
      end

      def clear_static(interface_id, network_id)
        transaction {
          get_model(interface_id, network_id).tap { |model|
            next if model.nil?

            if !leases_empty?(interface_id, network_id)
              return update_model_no_validate(model, static: false)
            end

            internal_update(model, static: false)
            internal_destroy(model)
          }
        }.tap { |model|
          next if model.nil?
          dispatch_deleted_item_events(model)
        }
      end

      #
      # Internal methods:
      #

      private

      def get_model(interface_id, network_id)
        M::InterfaceNetwork[interface_id: interface_id, network_id: network_id]
      end

      def leases_empty?(interface_id, network_id)
        M::IpLease.dataset.where(interface_id: interface_id).networks.where(networks__id: network_id).empty?
      end

      def dispatch_created_item_events(model)
        dispatch_event(INTERFACE_NETWORK_CREATED_ITEM, model.to_hash)
      end

      def dispatch_updated_item_events(model, changed_keys)
        dispatch_event(INTERFACE_NETWORK_UPDATED_ITEM, get_changed_hash(model, changed_keys))
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(INTERFACE_NETWORK_DELETED_ITEM, id: model.id)
      end

    end
  end
end
