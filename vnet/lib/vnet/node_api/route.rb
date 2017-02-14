# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class Route < EventBase
    valid_update_fields []

    class << self
      private

      def create_with_transaction(options)
        transaction {
          handle_new_uuid(options)

          model_class.create(options).tap { |model|
            next if model.nil?
            InterfaceRouteLink.update_assoc(model.interface_id, model.route_link_id)
          }
        }
      end

      def destroy_with_transaction(filter)
        transaction {
          internal_destroy(model_class[filter]).tap { |model|
            next if model.nil?
            InterfaceRouteLink.update_assoc(model.interface_id, model.route_link_id)
          }
        }
      end

      def dispatch_created_item_events(model)
        dispatch_event(ROUTE_CREATED_ITEM, model.to_hash)
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(ROUTE_DELETED_ITEM, id: model.id)

        # no dependencies
      end

    end
  end
end
