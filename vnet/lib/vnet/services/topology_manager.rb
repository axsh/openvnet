# -*- coding: utf-8 -*-

module Vnet::Services

  class TopologyManager < Vnet::Manager
    #
    # Events:
    #
    # event_handler_default_drop_all

    subscribe_event TOPOLOGY_INITIALIZED, :load_item
    subscribe_event TOPOLOGY_UNLOAD_ITEM, :unload_item
    subscribe_event TOPOLOGY_CREATED_ITEM, :created_item
    subscribe_event TOPOLOGY_DELETED_ITEM, :unload_item

    def initialize(info, options = {})
      super
      @log_prefix = "#{self.class.name.to_s.demodulize.underscore}: "
    end

    #
    # Internal methods:
    #

    private

    #
    # Specialize Manager:
    #

    def mw_class
      MW::Topology
    end

    def initialized_item_event
      TOPOLOGY_INITIALIZED
    end

    def item_unload_event
      TOPOLOGY_UNLOAD_ITEM
    end

    def match_item_proc_part(filter_part)
      filter, value = filter_part

      case filter
      when :id
        proc { |id, item| value == item.send(filter) }
      else
        raise NotImplementedError, filter
      end
    end

    def query_filter_from_params(params)
      filter = []
      filter << {id: params[:id]} if params.has_key? :id
      filter
    end

    def item_initialize(item_map)
      item_class = Topologies::Base

      item = item_class.new(dp_info: @dp_info, map: item_map)
    end

    #
    # Create / Delete events:
    #

    def item_pre_install(item, item_map)
    end

    def item_post_install(item, item_map)
    end
    
    # item created in db on queue 'item.id'
    def created_item(params)
      return if internal_detect_by_id(params)

      internal_new_item(mw_class.new(params))
    end

  end

end
