module Vnet::Services
  class IpRetentionContainerManager < Vnet::Manager
    DEFAULT_OPTIONS = {
      expiration_check_interval: 60,
      run: true,
    }

    subscribe_event IP_RETENTION_CONTAINER_INITIALIZED, :load_item
    subscribe_event IP_RETENTION_CONTAINER_UNLOAD_ITEM, :unload_item
    subscribe_event IP_RETENTION_CONTAINER_CREATED_ITEM, :created_item
    subscribe_event IP_RETENTION_CONTAINER_DELETED_ITEM, :unload_item

    subscribe_event IP_RETENTION_CONTAINER_CHECK_LEASE_TIME_EXPIRATION, :check_lease_time_expiration
    subscribe_event IP_RETENTION_CONTAINER_CHECK_GRACE_TIME_EXPIRATION, :check_grace_time_expiration

    subscribe_event IP_RETENTION_CONTAINER_ADDED_IP_RETENTION, :add_ip_retention
    subscribe_event IP_RETENTION_CONTAINER_REMOVED_IP_RETENTION, :remove_ip_retention

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
            publish(IP_RETENTION_CONTAINER_CREATED_ITEM, id: ip_retention.id)
          end
        end
        i += 1
      end
    end

    def created_item(params)
      return if @items[params[:id]]

      internal_new_item(mw_class.new(params), {})
    end

    def mw_class
      MW::IpRetentionContainer
    end

    def item_initialize(item_map, params)
      IpRetentionContainers::Base.new(item_map)
    end

    def initialized_item_event
      IP_RETENTION_CONTAINER_INITIALIZED
    end

    def item_unload_event
      IP_RETENTION_CONTAINER_UNLOAD_ITEM
    end

    #def match_item_proc_part(filter_part)
    #  filter, value = filter_part

    #  case filter
    #  when :id, :uuid
    #    proc { |id, item| value == item.send(filter) }
    #  when :lease_time_expired_at
    #    proc { |id, item| value >= item.lease_time_expired_at }
    #  when :grace_time_expired_at
    #    proc { |id, item| item.grace_time_expired_at && value >= item.grace_time_expired_at }
    #  else
    #    raise NotImplementedError, filter
    #  end
    #end

    def query_filter_from_params(params)
      [].tap do |filter|
        filter << {id: params[:id]} if params.has_key? :id
      end
    end

    def add_ip_retention(params)
      item = @items[params[:id]]
      return unless item

      item.add_ip_retention(
        id: params[:ip_retention_id],
        ip_lease_id: params[:ip_lease_id],
        lease_time_expired_at: params[:lease_time_expired_at]
      )
    end

    def remove_ip_retention(params)
      item = @items[params[:id]]
      return unless item

      item.remove_ip_retention(params[:ip_retention_id])
    end

    def check_expiration
      @items.each do |item|
        dispatch_event(IP_RETENTION_CONTAINER_CHECK_LEASE_TIME_EXPIRATION, id: item.id)
        dispatch_event(IP_RETENTION_CONTAINER_CHECK_GRACE_TIME_EXPIRATION, id: item.id)
      end
    end

    def check_lease_time_expiration(params)
      item = @items[params[:id]]
      return unless item

      item.check_lease_time_expiration
    end

    def check_grace_time_expiration(params)
      item = @items[params[:id]]
      return unless item

      item.check_grace_time_expiration
    end
  end
end
