module Vnet::Models
  class IpRetention < Base
    many_to_one :ip_lease
    many_to_one :ip_retention_container

    def expire
      if ip_retention_container.grace_time
        self.grace_time_expired_at = Time.now + ip_retention_container.grace_time
        save_changes
      else
        destroy
      end
    end

    def before_create
      # Time.now might be different from created_at
      self.lease_time_expired_at = Time.now + self.ip_retention_container.lease_time.to_i
    end
  end
end
