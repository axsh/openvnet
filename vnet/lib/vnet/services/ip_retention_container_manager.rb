# -*- coding: utf-8 -*-

module Vnet::Services

  class IpRetentionContainerManager < Vnet::Manager
    DEFAULT_OPTIONS = {
      expiration_check_interval: 60,
      run: true,
    }

    #
    # Events:
    #
    subscribe_event IP_RETENTION_CONTAINER_INITIALIZED, :load_item
    subscribe_event IP_RETENTION_CONTAINER_UNLOAD_ITEM, :unload_item
    subscribe_event IP_RETENTION_CONTAINER_CREATED_ITEM, :created_item
    subscribe_event IP_RETENTION_CONTAINER_DELETED_ITEM, :unload_item

    subscribe_event IP_RETENTION_CONTAINER_ADDED_IP_RETENTION, :added_ip_retention
    subscribe_event IP_RETENTION_CONTAINER_REMOVED_IP_RETENTION, :removed_ip_retention
    subscribe_event IP_RETENTION_CONTAINER_LEASE_TIME_EXPIRED, :lease_time_expired
    subscribe_event IP_RETENTION_CONTAINER_GRACE_TIME_EXPIRED, :grace_time_expired

    def initialize(info, options = {})
      super
      @log_prefix = "#{self.class.name.to_s.demodulize.underscore}: "
      @options = DEFAULT_OPTIONS.merge(options)
      async.run if @options[:run]
    end

    #
    # Internal methods:
    #

    private

    #
    # Specialize Manager:
    #

    def mw_class
      MW::IpRetentionContainer
    end

    def initialized_item_event
      IP_RETENTION_CONTAINER_INITIALIZED
    end

    def item_unload_event
      IP_RETENTION_CONTAINER_UNLOAD_ITEM
    end

    def match_item_proc_part(filter_part)
      filter, value = filter_part

      case filter
      when :id, :uuid
        proc { |id, item| value == item.send(filter) }
      else
        raise NotImplementedError, filter
      end
    end

    def query_filter_from_params(params)
      [].tap do |filter|
        filter << {id: params[:id]} if params.has_key? :id
      end
    end

    def item_initialize(item_map)
      IpRetentionContainers::Base.new(item_map)
    end

    #
    # Create / Delete events:
    #

    def created_item(params)
      return if @items[params[:id]]

      internal_new_item(mw_class.new(params))
    end

    def item_post_install(item, item_map)
      load_ip_retentions(item)
    end

    #
    # Event handlers:
    #

    # IP_RETENTION_CONTAINER_ADDED_IP_RETENTION on queue 'item.id'
    def added_ip_retention(params)
      item = @items[params[:id]]
      return unless item

      item.add_ip_retention(
        id: params[:ip_retention_id],
        ip_lease_id: params[:ip_lease_id],
        leased_at: params[:leased_at],
        released_at: params[:released_at]
      )
    end

    # IP_RETENTION_CONTAINER_REMOVED_IP_RETENTION on queue 'item.id'
    def removed_ip_retention(params)
      item = @items[params[:id]]
      return unless item

      item.remove_ip_retention(params[:ip_retention_id])
    end

    # IP_RETENTION_CONTAINER_LEASE_TIME_EXPIRED on queue 'item.id'
    def lease_time_expired(params)
      item = @items[params[:id]]
      return unless item

      item.lease_time_expired
    end

    # IP_RETENTION_CONTAINER_GRACE_TIME_EXPIRED on queue 'item.id'
    def grace_time_expired(params)
      item = @items[params[:id]]
      return unless item

      item.grace_time_expired
    end

    #
    # Helper methods:
    #

    def run
      load_all_items
      every(@options[:expiration_check_interval]) { check_expiration }
    end

    def load_all_items
      # OPTIMIZE
      #
      # This should be done within the safety of the manager
      # inititialization stage where events are queued. That means the
      # events should be removed.

      i = 1
      loop do
        mw_class.batch.dataset.paginate(i, 10000).all.commit.tap do |ip_retention_containers|
          return if ip_retention_containers.empty?
          ip_retention_containers.each do |ip_retention_container|
            publish(
              IP_RETENTION_CONTAINER_CREATED_ITEM,
              id: ip_retention_container.id
            )
          end
        end
        i += 1
      end
    end

    def load_ip_retentions(item)
      # OPTIMIZE
      #
      # This should happen while the item locks the item.id queue, so
      # no events should be needed.

      i = 1
      loop do
        mw_class.batch[item.id].ip_retentions_dataset.paginate(i, 10000).all.commit.tap do |ip_retentions|
          return if ip_retentions.empty?
          ip_retentions.each do |ip_retention|
            publish(
              IP_RETENTION_CONTAINER_ADDED_IP_RETENTION,
              id: item.id,
              ip_retention_id: ip_retention.id,
              ip_lease_id: ip_retention.ip_lease_id,
              leased_at: ip_retention.leased_at,
              released_at: ip_retention.released_at
            )
          end
        end
        i += 1
      end
    end

    def check_expiration
      @items.values.each do |item|
        item.check_lease_time_expiration
        item.check_grace_time_expiration
      end
    end
  end
end
