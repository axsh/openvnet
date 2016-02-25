# -*- coding: utf-8 -*-

module Vnet::NodeApi

  class DatapathGeneric < EventBase
    class << self
      private

      def create_with_transaction(options)
        if options[:ip_lease_id].nil?
          options = options.dup
          options[:ip_lease_id] = find_ip_lease_id(options[:interface_id])
        end

        transaction {
          mac_address_random_assign(options)
          model = internal_create(options)
        }
      end

      def destroy_with_transaction(datapath_id: datapath_id, generic_id: generic_id)
        internal_destroy(model_class[datapath_id, generic_id])
      end

      def model_to_event_hash(model)
        model.to_hash.tap { |event_hash|
          prepare_event_hash(event_hash)
        }
      end

      def find_ip_lease_id(interface_id)
        return if interface_id.nil?

        ip_lease = model_class(:ip_lease).dataset.where(interface_id: interface_id).first
        ip_lease && ip_lease.id
      end

    end
  end

  class DatapathNetwork < DatapathGeneric
    class << self
      private

      def dispatch_created_item_events(model)
        dispatch_event(ADDED_DATAPATH_NETWORK, prepare_event_hash(model))
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(REMOVED_DATAPATH_NETWORK, prepare_event_hash(model))
      end

      def destroy_filter(datapath_id, generic_id)
        { datapath_id: datapath_id, network_id: generic_id }
      end

      def prepare_event_hash(model)
        model.to_hash.tap { |event_hash|
          event_hash[:dpn_id] = event_hash[:id]
          event_hash[:id] = event_hash[:datapath_id]
        }
      end

    end
  end

  class DatapathRouteLink < DatapathGeneric
    class << self
      private

      def dispatch_created_item_events(model)
        dispatch_event(ADDED_DATAPATH_ROUTE_LINK, prepare_event_hash(model))
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(REMOVED_DATAPATH_ROUTE_LINK, prepare_event_hash(model))
      end

      def destroy_filter(datapath_id, generic_id)
        { datapath_id: datapath_id, route_link_id: generic_id }
      end

      def prepare_event_hash(model)
        model.to_hash.tap { |event_hash|
          event_hash[:dprl_id] = event_hash[:id]
          event_hash[:id] = event_hash[:datapath_id]
        }
      end

    end
  end

end
