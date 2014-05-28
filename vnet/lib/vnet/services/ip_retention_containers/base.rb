module Vnet::Services::IpRetentionContainers
  class IpRetention < Vnet::ItemVnetBase
    attr_accessor :ip_lease_id, :lease_time_expired_at, :grace_time_expired_at
    def initialize(params)
      super
      @ip_lease_id = params[:ip_lease_id]
      @lease_time_expired_at = params[:lease_time_expired_at]
    end

    def to_hash
      {
        id: id,
        ip_lease_id: ip_lease_id,
        lease_time_expired_at: lease_time_expired_at,
        grace_time_expired_at: grace_time_expired_at,
      }
    end

    def log_type
      "ip_retention"
    end
  end

  class Base << Vnet::ItemVnetBase
    attr_accessor :lease_time, :grace_time, :ip_retentions
    def initialize(params)
      super
      @lease_time = params[:lease_time]
      @grace_time = params[:grace_time]
      @ip_retentions = {}
    end

    def add_ip_retention(params)
      @ip_retentions[params[:id]] = IpRetention.new(params)
    end

    def remove_ip_retention(id)
      @ip_retentions.delete(id)
    end

    def check_lease_time_expiration
      current_time = Time.now 

      @ip_retentions.each do |_, ip_retention|
        next unless ip_retention.lease_time_expired_at
        next if current_time < ip_retention.lease_time_expired_at

        MW::IpLease.expire(ip_retention[:ip_lease_id])

        ip_retention.grace_time_expired_at = current_time + grace_time.to_i

        info("Released exipred ip_lease: #{ip_retention[:ip_lease_id]}")
      end
    end

    def check_grace_time_expiration
      current_time = Time.now 

      @ip_retentions.each do |id, ip_retention|
        next unless ip_retention.grace_time_expired_at
        next if current_time < ip_retention.grace_time_expired_at

        MW::IpRetentionContainer.remove_ip_retention(id)

        info("Destroyed exipred ip_retention: #{id}")
      end
    end

    def to_hash
      {
        id: id,
        lease_time: lease_time,
        grace_time: grace_time
      }
    end

    def log_type
      "ip_retention_container"
    end
  end
end
