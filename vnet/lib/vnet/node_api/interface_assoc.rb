# -*- coding: utf-8 -*-

# This association does not allow direct creation/destrucion of
# entries.
#
# Instead it automatically manages the lifetime of the association
# depending on if there is an association or not, and allows for
# persistency if 'static' is true.

module Vnet::NodeApi

  class InterfaceAssoc < EventBase
    class << self

      def create(options)
        raise NotImplementedError
      end

      def destroy(filter)
        raise NotImplementedError
      end

      # TODO: Improve so that e.g. destroying a mac_lease updates
      # ip_lease assocs.

      def update_assoc(parent_id, other_id)
        return if parent_id.nil? || other_id.nil?

        transaction {
          model = get_model(parent_id, other_id)

          if model && model.static
            next model, nil
          end

          if leases_empty?(parent_id, other_id)
            next internal_destroy(model), :destroy if model
          else
            next create_model(parent_id, other_id, false), :create if model.nil?
          end

        }.tap { |model, action|
          return if model.nil?

          case action
          when :create then dispatch_created_item_events(model)
          when :destroy then dispatch_created_item_events(model)
          end

          return model
        }
      end

      # TODO: Change to call update_assoc after changing static.
      def set_static(parent_id, other_id)
        transaction {
          get_model(parent_id, other_id).tap { |model|
            return update_model_no_validate(model, static: true) if model
          }

          create_model(parent_id, other_id, true)

        }.tap { |model|
          next if model.nil?
          dispatch_created_item_events(model)
        }
      end

      def clear_static(parent_id, other_id)
        transaction {
          get_model(parent_id, other_id).tap { |model|
            next if model.nil?

            if !leases_empty?(parent_id, other_id)
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

      def get_model(parent_id, other_id)
        raise NotImplementedError
      end

      def create_model(parent_id, other_id, static)
        raise NotImplementedError
      end

      def leases_empty?(parent_id, other_id)
        raise NotImplementedError
      end

    end
  end

  class InterfaceNetwork < InterfaceAssoc
    class << self

      private

      def get_model(parent_id, other_id)
        M::InterfaceNetwork[interface_id: parent_id, network_id: other_id]
      end

      def create_model(parent_id, other_id, static)
        internal_create(interface_id: parent_id, network_id: other_id, static: static)
      end

      def leases_empty?(parent_id, other_id)
        M::IpLease.dataset.where(interface_id: parent_id).networks.where(networks__id: other_id).empty?
      end

      def dispatch_created_item_events(model)
        dispatch_event(INTERFACE_NETWORK_CREATED_ITEM, model.to_hash)
      end

      def dispatch_updated_item_events(model, old_values)
        dispatch_event(INTERFACE_NETWORK_UPDATED_ITEM, get_changed_hash(model, old_values.keys))
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(INTERFACE_NETWORK_DELETED_ITEM, id: model.id)
      end

    end
  end

  class InterfaceSegment < InterfaceAssoc
    class << self

      private

      def get_model(parent_id, other_id)
        M::InterfaceSegment[interface_id: parent_id, segment_id: other_id]
      end

      def create_model(parent_id, other_id, static)
        internal_create(interface_id: parent_id, segment_id: other_id, static: static)
      end

      def leases_empty?(parent_id, other_id)
        M::MacLease.dataset.where(interface_id: parent_id).segments.where(segments__id: other_id).empty?
      end

      def dispatch_created_item_events(model)
        dispatch_event(INTERFACE_SEGMENT_CREATED_ITEM, model.to_hash)
      end

      def dispatch_updated_item_events(model, old_values)
        dispatch_event(INTERFACE_SEGMENT_UPDATED_ITEM, get_changed_hash(model, old_values.keys))
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(INTERFACE_SEGMENT_DELETED_ITEM, id: model.id)
      end

    end
  end

  class InterfaceRouteLink < InterfaceAssoc
    class << self

      private

      def get_model(parent_id, other_id)
        M::InterfaceRouteLink[interface_id: parent_id, route_link_id: other_id]
      end

      def create_model(parent_id, other_id, static)
        internal_create(interface_id: parent_id, route_link_id: other_id, static: static)
      end

      def leases_empty?(parent_id, other_id)
        M::Route.dataset.where(interface_id: parent_id, route_link_id: other_id).empty?
      end

      def dispatch_created_item_events(model)
        dispatch_event(INTERFACE_ROUTE_LINK_CREATED_ITEM, model.to_hash)
      end

      def dispatch_updated_item_events(model, old_values)
        dispatch_event(INTERFACE_ROUTE_LINK_UPDATED_ITEM, get_changed_hash(model, old_values.keys))
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(INTERFACE_ROUTE_LINK_DELETED_ITEM, id: model.id)
      end

    end
  end

end
