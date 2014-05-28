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
  end
end
