# -*- coding: utf-8 -*-

module Vnet::Core

  class HostDatapathManager < Vnet::Core::Manager
    include Vnet::Openflow::FlowHelpers

    #
    # Events:
    #

    subscribe_event HOST_DATAPATH_INITIALIZED, :load_item
    subscribe_event HOST_DATAPATH_UNLOAD_ITEM, :unload_item
    subscribe_event DATAPATH_CREATED_ITEM, :created_item
    subscribe_event DATAPATH_DELETED_ITEM, :unload_item

    #
    # Internal methods:
    #

    private

    #
    # Specialize Manager:
    #

    def mw_class
      MW::Datapath
    end

    def initialized_item_event
      HOST_DATAPATH_INITIALIZED
    end

    def item_unload_event
      HOST_DATAPATH_UNLOAD_ITEM
    end

    def match_item_proc_part(filter_part)
      filter, value = filter_part

      case filter
      when :id, :uuid, :dpid
        proc { |id, item| value == item.send(filter) }
      else
        raise NotImplementedError, filter
      end
    end

    def query_filter_from_params(params)
      filter = []
      filter << {id: params[:id]} if params.has_key? :id
      filter << {dpid: params[:dpid]} if params.has_key? :dpid
      filter
    end

    def item_initialize(item_map)
      item_class = HostDatapaths::Base
      item_class.new(dp_info: @dp_info, map: item_map)
    end

    #
    # Create / Delete events:
    #

    def item_post_install(item, item_map)
      if item.dpid != @dp_info.dpid
        raise log_format('tried to load host datapath with unexpected datapath id',
                         "dpid:%#x" % item.dpid)
      end

      # TODO: Add warning if node_id does not match current node.
    end

    def created_item(params)
      # We are only interested in the datapath that has the dpid
      # (datapath id) of the current OpenFlow datapath.
      return if internal_detect_by_id(params)
      return if @dp_info.dpid != params[:dpid]

      internal_new_item(mw_class.new(params))
    end

  end
end
