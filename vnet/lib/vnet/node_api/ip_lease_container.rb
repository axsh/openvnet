module Vnet::NodeApi
  class IpLeaseContainer < EventBase
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
        # dispatch_event(, id: model.id)
      end

    end
  end
end
