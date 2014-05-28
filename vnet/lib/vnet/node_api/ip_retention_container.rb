module Vnet::NodeApi
  class IpRetentionContainer < Base
    class << self
      def create(options)
        super.tap do |ip_retention_container|
          dispatch_event(IP_RETENTION_CONTAINER_CREATED_ITEM, ip_retention_container.to_hash)
        end
      end

      def destroy(uuid)
        super.tap do |ip_retention_container|
          dispatch_event(IP_RETENTION_CONTAINER_CREATED_ITEM, ip_retention_container.to_hash)
        end
      end

      def add_ip_retention(id, options)
        ip_retention_container = model_class[id]
        lease_time_expired_at = ip_retention_container.lease_time ? Time.now + ip_retention_container.lease_time : nil
        ip_retention = ip_retention_container.add_ip_retention(
          ip_lease_id: options[:ip_lease_id],
          lease_time_expired_at: lease_time_expired_at
        )

        dispatch_event(IP_RETENTION_CONTAINER_CREATED_IP_RETENTION, id: ip_retention.id, ip_lease_id: ip_retention.ip_lease_id, lease_time_expired_at: ip_retention.lease_time_expired_at)
      end

      def remove_ip_retention(id, ip_retention_id)
        model_class[id].remove_ip_retentions(ip_retention_id)
        dispatch_event(IP_RETENTION_CONTAINER_DELETED_IP_RETENTION, id: id)
      end
    end
  end
end
