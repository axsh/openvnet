module Vnet::Services
  class IpRetention < Vnet::ItemBase
    attr_accessor :id, :ip_lease_id, :expired_at
    def initialize(params)
      @id = params[:id]
      @ip_lease_id = params[:ip_lease_id]
      @expired_at = params[:expired_at]
    end

    def to_hash
      {
        id: id,
        ip_lease_id: ip_lease_id,
        expired_at: expired_at,
      }
    end
  end

  class IpRetentionManager < Vnet::Manager
    DEFAULT_OPTIONS = {
      release_interval: 60,
      run: true,
    }

    subscribe_event IP_RETENTION_INITIALIZED, :load_item
    subscribe_event IP_RETENTION_UNLOAD_ITEM, :unload_item
    subscribe_event IP_RETENTION_CREATED_ITEM, :create_item
    subscribe_event IP_RETENTION_DELETED_ITEM, :unload_item

    def initialize(info, options = {})
      super
      @options = DEFAULT_OPTIONS.merge(options)
      async.run if options[:run]
    end

    def run
      every(@options[:release_interval]) { release_expired }
    end

    def create_item(params)
      return if @items[params[:id]]

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

    def query_filter_from_params(params)
      [].tap do |filter|
        filter << {id: params[:id]} if params.has_key? :id
      end
    end

    def match_item?(item, params)
      return false if params[:expired_at] && params[:expired_at] < item.expired_at
      return super
    end

    def release_expired
      internal_select(expired_at: Time.now).each do |item|
        MW::IpLease.destroy(item.ip_lease_id)
        info("Released exipred ip_lease: #{item.ip_lease_id}")
      end
    end
  end
end
