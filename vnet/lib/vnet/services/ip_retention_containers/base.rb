module Vnet::Services::IpRetentionContainers
  class IpRetention
    attr_accessor :id
    attr_accessor :ip_lease_id
    attr_accessor :lease_time_expired_at
    attr_accessor :grace_time_expired_at
    attr_accessor :lease_time_expired_at_i
    attr_accessor :grace_time_expired_at_i

    def initialize(params)
      self.id = params[:id]
      self.ip_lease_id = params[:ip_lease_id]
      self.lease_time_expired_at = params[:lease_time_expired_at]
      self.lease_time_expired_at_i = lease_time_expired_at.to_i if lease_time_expired_at
    end

    def expire!(grace_time)
      self.grace_time_expired_at = lease_time_expired_at + grace_time
      self.grace_time_expired_at_i = grace_time_expired_at.to_i
    end

    def lease_time_expired?
      lease_time_expired_at && lease_time_expired_at_i <= Time.now.to_i
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

  class Base < Vnet::ItemVnetBase
    include Vnet::Event

    MW = Vnet::ModelWrappers

    attr_accessor :lease_time
    attr_accessor :grace_time
    attr_accessor :ip_retentions
    attr_accessor :lease_time_ip_retentions
    attr_accessor :grace_time_ip_retentions

    def initialize(params)
      super
      @lease_time = params[:lease_time]
      @grace_time = params[:grace_time]
      @ip_retentions = {}
      @lease_time_ip_retentions = []
      @grace_time_ip_retentions = []
    end

    def add_ip_retention(params)
      return unless installed?

      ip_retention = IpRetention.new(params)

      @ip_retentions[params[:id]] = ip_retention

      if ip_retention.lease_time_expired_at
        @lease_time_ip_retentions << ip_retention
        @lease_time_ip_retentions.sort_by! { |i| i.lease_time_expired_at_i }
      end

      ip_retention
    end

    def remove_ip_retention(id)
      ip_retention = @ip_retentions.delete(id)
      return unless ip_retention

      @lease_time_ip_retentions.delete(ip_retention)
      @grace_time_ip_retentions.delete(ip_retention)

      info log_format("removed ip_retention: #{id} ip_lease: #{ip_retention.ip_lease_id}")

      ip_retention
    end

    def expire_ip_retentions(ids)
      return unless installed?

      ids.each do |id|
        ip_retention = @ip_retentions[id]
        return unless ip_retention

        @lease_time_ip_retentions.delete(ip_retention)

        ip_retention.expire!(grace_time)

        @grace_time_ip_retentions << ip_retention
        @grace_time_ip_retentions.sort_by! { |i| i.grace_time_expired_at_i }

        MW::IpLease.expire(ip_retention.ip_lease_id)

        info log_format("exipred ip_retention: #{id} ip_lease: #{ip_retention.ip_lease_id}")
      end
    end

    def check_lease_time_expiration
      current_time = Time.now.to_i

      expired_ip_retentions = @lease_time_ip_retentions.reduce([]) do |array, ip_retention|
        break array if current_time < ip_retention.lease_time_expired_at_i
        array << ip_retention
        array
      end

      publish(
        IP_RETENTION_CONTAINER_EXPIRED_IP_RETENTION,
        id: id,
        ip_retention_ids: expired_ip_retentions.map(&:id)
      )
    end

    def check_grace_time_expiration
      current_time = Time.now.to_i

      expired_ip_retentions = @grace_time_ip_retentions.reduce([]) do |array, ip_retention|
        break array if current_time < ip_retention.grace_time_expired_at_i
        array << ip_retention
        array
      end

      expired_ip_retentions.each do |ip_retention|
        MW::IpRetentionContainer.remove_ip_retention(id: id, ip_retention_id: ip_retention.id)
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

    private

    def publish(event, options)
      Celluloid::Actor.current.publish(event, options)
    end
  end
end
