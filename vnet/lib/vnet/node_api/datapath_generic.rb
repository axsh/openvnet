# -*- coding: utf-8 -*-

module Vnet::NodeApi

  class DatapathGeneric < Base
    class << self

      def create(options)
        options = options.dup

        if options[:ip_lease_id].nil?
          options[:ip_lease_id] = find_ip_lease_id(options[:interface_id])
        end

        dp_obj = transaction {
          model_class.create(options)
        }.tap { |model|
          next if model.nil?
          dispatch_event(event_added, model_to_event_hash(model))
        }
      end

      def destroy(datapath_id: datapath_id, generic_id: generic_id)
        filter = destroy_filter(datapath_id, generic_id)

        transaction {
          model_class.find(filter).tap(&:destroy)
        }.tap { |model|
          next if model.nil?
          dispatch_event(event_removed, model_to_event_hash(model))
        }
      end

      #
      # Internal methods:
      #

      private

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

      def event_added
        ADDED_DATAPATH_NETWORK
      end

      def event_removed
        REMOVED_DATAPATH_NETWORK
      end

      def destroy_filter(datapath_id, generic_id)
        { datapath_id: datapath_id, network_id: generic_id }
      end

      def prepare_event_hash(event_hash)
        event_hash[:dpn_id] = event_hash[:id]
        event_hash[:id] = event_hash[:datapath_id]
      end

    end
  end

  class DatapathRouteLink < DatapathGeneric
    class << self
      private

      def event_added
        ADDED_DATAPATH_ROUTE_LINK
      end

      def event_removed
        REMOVED_DATAPATH_ROUTE_LINK
      end

      def destroy_filter(datapath_id, generic_id)
        { datapath_id: datapath_id, route_link_id: generic_id }
      end

      def prepare_event_hash(event_hash)
        event_hash[:dprl_id] = event_hash[:id]
        event_hash[:id] = event_hash[:datapath_id]
      end

    end
  end

end
