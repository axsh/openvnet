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

        ip_retention = nil
        transaction do
          ip_retention = ip_retention_container.add_ip_retention(
            ip_lease_id: options[:ip_lease_id],
            lease_time_expired_at: lease_time_expired_at
          )
        end

        dispatch_event(IP_RETENTION_CONTAINER_CREATED_IP_RETENTION, id: ip_retention.id, ip_lease_id: ip_retention.ip_lease_id, lease_time_expired_at: ip_retention.lease_time_expired_at)

        ip_retention
      end

      def remove_ip_retention(id, ip_retention_id)
        ip_retention = model_class(:ip_retention)[ip_retention_id]
        unless ip_retention.ip_retention_container_id == id
          raise "Invalid ip_retention_container. ip_retention_container: #{id} ip_retention: #{ip_retention_id}"
        end

        transaction do
          ip_retention.destroy
        end

        dispatch_event(IP_RETENTION_CONTAINER_DELETED_IP_RETENTION, id: id)

        ip_retention
      end
    end
  end
end
