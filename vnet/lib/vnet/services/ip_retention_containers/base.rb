module Vnet::Services::IpRetentionContainers
  class IpRetention
    attr_reader :id
    attr_reader :ip_lease_id
    attr_reader :leased_at
    attr_reader :leased_at_i
    attr_reader :released_at
    attr_reader :released_at_i

    def initialize(params)
      @id = params[:id]
      @ip_lease_id = params[:ip_lease_id]
      @leased_at = params[:leased_at]
      @leased_at_i = leased_at.to_i if leased_at
      @released_at = params[:released_at]
      @released_at_i = released_at.to_i if released_at
    end

    def to_hash
      {
        id: id,
        ip_lease_id: ip_lease_id,
        leased_at: leased_at,
        released_at: released_at,
      }
    end

    def log_type
      "ip_retention"
    end
  end

  class Base < Vnet::ItemVnetBase
    include Vnet::Event

    MW = Vnet::ModelWrappers

    attr_reader :lease_time
    attr_reader :grace_time
    attr_reader :leased_ip_retentions
    attr_reader :released_ip_retentions

    def initialize(params)
      super
      @lease_time = params[:lease_time]
      @grace_time = params[:grace_time]
      @ip_retentions = {}
      @leased_ip_retentions = []
      @released_ip_retentions = []
    end

    def add_ip_retention(params)
      return unless installed?

      ip_retention = IpRetention.new(params)

      @ip_retentions[ip_retention.id] = ip_retention

      if ip_retention.released_at
        @released_ip_retentions << ip_retention
        @released_ip_retentions.sort_by! { |i| i.released_at_i }
      else
        @leased_ip_retentions << ip_retention
        @leased_ip_retentions.sort_by! { |i| i.leased_at_i }
      end

      ip_retention
    end

    # force remove an ip_retention
    def remove_ip_retention(id)
      @ip_retentions.delete(id).tap do |ip_retention|
        return unless ip_retention

        info log_format("removed ip_retention: #{id} ip_lease: #{ip_retention.ip_lease_id}")

        [@leased_ip_retentions, @released_ip_retentions].each do |ip_retentions|
          index = nil
          ip_retentions.each_with_index do |ip_retention, i|
            if ip_retention.id == id
              index = i
              break
            end
          end

          if index
            ip_retentions.delete_at(index)
            break
          end
        end
      end
    end

    def lease_time_expired
      return unless installed?

      current_time =  Time.now.to_i
      count = 0
      @leased_ip_retentions.each do |ip_retention|
        break unless ip_retention.leased_at_i + lease_time <= current_time
        count += 1
      end

      return if count == 0

      @leased_ip_retentions.shift(count).each do |ip_retention|
        MW::IpLease.release(ip_retention.ip_lease_id)
        info log_format("lease time expired. ip_retention: #{id} ip_lease: #{ip_retention.ip_lease_id}")
      end
    end

    def grace_time_expired
      return unless installed?

      current_time =  Time.now.to_i
      count = 0
      @released_ip_retentions.each do |ip_retention|
        break unless ip_retention.released_at_i + grace_time <= current_time
        count += 1
      end

      return if count == 0

      @released_ip_retentions.shift(count).each do |ip_retention|
        MW::IpLease.destroy(ip_retention.ip_lease_id)
        info log_format("grace time expired. ip_retention: #{id} ip_lease: #{ip_retention.ip_lease_id}")
      end
    end

    def check_lease_time_expiration
      return if @leased_ip_retentions.empty?
      return unless @leased_ip_retentions.first.leased_at_i + lease_time <= Time.now.to_i

      publish(IP_RETENTION_CONTAINER_LEASE_TIME_EXPIRED, id: id)
    end

    def check_grace_time_expiration
      return if @released_ip_retentions.empty?
      return unless @released_ip_retentions.first.released_at_i + grace_time <= Time.now.to_i

      publish(IP_RETENTION_CONTAINER_GRACE_TIME_EXPIRED, id: id)
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

    private

    def publish(event, options)
      Celluloid::Actor.current.publish(event, options)
    end
  end
end
