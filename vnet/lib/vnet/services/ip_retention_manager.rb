module Vnet::Services
  class IpRetention < Vnet::ItemVnetBase
    attr_accessor :ip_lease_id, :lease_time_expired_at, :grace_time, :grace_time_expired_at
    def initialize(params)
      super
      @ip_lease_id = params[:ip_lease_id]
      @lease_time_expired_at = params[:lease_time_expired_at]
      @grace_time = params[:grace_time]
    end

    def to_hash
      {
        id: id,
        ip_lease_id: ip_lease_id,
        lease_time_expired_at: lease_time_expired_at,
        grace_time: grace_time,
        grace_time_expired_at: grace_time_expired_at,
      }
    end

    def log_type
      "ip_retention"
    end
  end

  class IpRetentionManager < Vnet::Manager
    DEFAULT_OPTIONS = {
      expiration_check_interval: 60,
      run: true,
    }

    subscribe_event IP_RETENTION_INITIALIZED, :load_item
    subscribe_event IP_RETENTION_UNLOAD_ITEM, :unload_item
    subscribe_event IP_RETENTION_CREATED_ITEM, :created_item
    subscribe_event IP_RETENTION_DELETED_ITEM, :unload_item
    subscribe_event IP_RETENTION_EXPIRED_ITEM, :expire_item

    def initialize(info, options = {})
      super
      @log_prefix = self.class.name.to_s.demodulize.underscore
      @options = DEFAULT_OPTIONS.merge(options)
      async.run if options[:run]
    end

    def run
      load_all_items
      every(@options[:expiration_check_interval]) { check_expiration }
    end

    def load_all_items(params)
      i = 1
      loop do
        mw_class.batch.dataset.paginate(i, 1000).all.commit.tap do |ip_retentions|
          return if ip_retentions.empty?
          ip_retentions.each do |ip_retention|
            publish(IP_RETENTION_CREATED_ITEM, id: ip_retention.id)
          end
        end
        i += 1
      end
    end

    def created_item(params)
      return if item = internal_detect_by_id(params)

      internal_new_item(mw_class.new(params), {})
    end

    def mw_class
      MW::IpRetention
    end

    def item_initialize(item_map, params)
      IpRetention.new(item_map)
    end

    def initialized_item_event
      IP_RETENTION_INITIALIZED
    end

    def item_unload_event
      IP_RETENTION_UNLOAD_ITEM
    end

    def match_item_proc_part(filter_part)
      filter, value = filter_part

      case filter
      when :id, :uuid
        proc { |id, item| value == item.send(filter) }
      when :lease_time_expired_at
        proc { |id, item| value >= item.lease_time_expired_at }
      when :grace_time_expired_at
        proc { |id, item| item.grace_time_expired_at && value >= item.grace_time_expired_at }
      else
        raise NotImplementedError, filter
      end
    end

    def query_filter_from_params(params)
      [].tap do |filter|
        filter << {id: params[:id]} if params.has_key? :id
      end
    end

    def expire_item(params)
      unless params[:grace_time_expired_at]
        error(log_format("grace_time_expired_at must be specified"))
        return
      end

      @items[params[:id]].tap do |item|
        return unless item
        item.grace_time_expired_at = params[:grace_time_expired_at]
      end
    end

    def check_expiration
      check_lease_time_expiration
      check_grace_time_expiration
    end

    def check_lease_time_expiration
      select(lease_time_expired_at: Time.now).each do |item|
        MW::IpLease.destroy(item[:ip_lease_id])
        info("Released exipred ip_lease: #{item[:ip_lease_id]}")
      end
    end

    def check_grace_time_expiration
      select(grace_time_expired_at: Time.now).each do |item|
        MW::IpRetention.destroy(item[:id])
        info("Destroyed exipred ip_retention: #{item[:id]}")
      end
    end
  end
end
