# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class IpRetention < EventBase
    class << self
      private

      # TODO: Rename event.

      def dispatch_created_item_events(model)
        dispatch_event(IP_RETENTION_CONTAINER_ADDED_IP_RETENTION, prepare_event_hash(model))
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(IP_RETENTION_CONTAINER_REMOVED_IP_RETENTION,
                       id: model.ip_retention_container_id,
                       ip_retention_id: model.id)

        # 0001_origin
        # ip_lease_container_ip_leases: send?
        # 0002_services
        # lease_policy_ip_lease_containers: send?
      end

      def prepare_event_hash(model)
        model.to_hash.tap { |event_hash|
          event_hash[:ip_retention_id] = event_hash[:id]
          event_hash[:id] = event_hash[:ip_retention_container_id]
        }
      end

    end
  end
end
