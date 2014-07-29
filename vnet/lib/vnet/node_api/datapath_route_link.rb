# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class DatapathRouteLink < Base
    class << self

      def create(options)
        options = options.dup

        dp_obj = transaction {

          if options[:ip_lease_id].nil?
            options[:ip_lease_id] = find_ip_lease_id(options[:interface_id])
          end

          model_class.create(options)

        }.tap { |model|
          next if model.nil?
          dispatch_event(ADDED_DATAPATH_ROUTE_LINK, model_to_event_hash(model))
        }
      end

      def destroy(datapath_id: datapath_id, route_link_id: route_link_id)
        transaction {
          model_class.find(datapath_id: datapath_id, route_link_id: route_link_id).tap(&:destroy)
        }.tap do |model|
          next if model.nil?
          dispatch_event(REMOVED_DATAPATH_ROUTE_LINK, model_to_event_hash(model))
        end
      end

      #
      # Internal methods:
      #

      private

      def model_to_event_hash(model)
        model.to_hash.tap { |event_hash|
          event_hash[:dprl_id] = event_hash[:id]
          event_hash[:id] = event_hash[:datapath_id]
        }
      end

      def find_ip_lease_id(interface_id)
        return if interface_id.nil?

        ip_lease = model_class(:ip_lease).dataset.where(interface_id: interface_id).first
        ip_lease && ip_lease.id
      end

    end
  end
end
