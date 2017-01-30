# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class Network < EventBase
    valid_update_fields [:display_name, :domain_name]

    class << self
      private

      def create_with_transaction(options)
        options = options.dup

        topology_id = options.delete(:topology_id)

        transaction {
          handle_new_uuid(options)

          internal_create(options).tap { |model|
            next if model.nil?

            M::TopologyNetwork.create(network_id: model.id, topology_id: topology_id)
          }
        }
      end

      def dispatch_created_item_events(model)
        filter = { network_id: model.id }

        # 0009_topology
        TopologyNetwork.dispatch_created_where(filter, model.created_at)
      end

      def dispatch_updated_item_events(model, old_values)
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(NETWORK_DELETED_ITEM, id: model.id)

        filter = { network_id: model.id }

        # 0001_origin
        ActiveNetwork.dispatch_deleted_where(filter, model.deleted_at)
        # IpAddresses.dispatch_deleted_where(filter, model.deleted_at) # Needed? We're deleting the network.
        DatapathNetwork.dispatch_deleted_where(filter, model.deleted_at)
        Route.dispatch_deleted_where(filter, model.deleted_at)
        # 0002_services
        # LeasePolicyBaseNetwork.dispatch_deleted_where(filter, model.deleted_at)
        # 0009_topology
        TopologyNetwork.dispatch_deleted_where(filter, model.deleted_at)
        # 0011_assoc_interface
        InterfaceNetwork.dispatch_deleted_where(filter, model.deleted_at)
      end

    end
  end
end
