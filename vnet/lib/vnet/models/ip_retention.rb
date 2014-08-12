module Vnet::Models

  # TODO: Refactor.
  class IpRetention < Base
    plugin :paranoia_is_deleted

    many_to_one :ip_lease
    many_to_one :ip_retention_container

    def expire
      if ip_retention_container.grace_time
        self.released_at = Time.now
        save_changes
      else
        destroy
      end
    end

    def before_create
      self.leased_at = Time.now
      super
    end
  end
end
