module Vnet::NodeApi
  class IpRetention < EventBase
    class << self
      private

      def dispatch_created_item_events(model)
        # dispatch_event(, model.to_hash)

        # 0001_origin
        # ip_lease_container_ip_leases: send?
        # 0002_services
        # lease_policy_ip_lease_containers: send?
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(IP_RETENTION_CONTAINER_REMOVED_IP_RETENTION,
                       id: model.ip_retention_container_id,
                       ip_retention_id: model.id)
      end

    end
  end
end
