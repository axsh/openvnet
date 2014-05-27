module Vnet::Models
  class IpRetention < Base
    many_to_one :ip_lease
    many_to_one :ip_address

    plugin :association_dependencies, ip_address: :destroy

    def expire
      if grace_time
        self.grace_time_expired_at = Time.now + grace_time
        save_changes
      else
        destroy
      end
    end

    def validate
      super
      errors.add(:grace_time, 'cannot be less than 0') if grace_time && grace_time < 0
    end
  end
end
