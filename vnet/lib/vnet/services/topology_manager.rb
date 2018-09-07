# -*- coding: utf-8 -*-

module Vnet::Services
  class TopologyManager < Vnet::Services::Manager
    include Vnet::Constants::Topology
    include Vnet::ManagerAssocs

    #
    # Events:
    #
    event_handler_default_drop_all

    subscribe_event TOPOLOGY_INITIALIZED, :load_item
    subscribe_event TOPOLOGY_UNLOAD_ITEM, :unload_item
    subscribe_event TOPOLOGY_CREATED_ITEM, :created_item
    subscribe_event TOPOLOGY_DELETED_ITEM, :unload_item

    subscribe_assoc_other_events :topology, :datapath
    subscribe_assoc_other_events :topology, :mac_range_group
    subscribe_assoc_other_events :topology, :network
    subscribe_assoc_other_events :topology, :segment
    subscribe_assoc_other_events :topology, :route_link

    subscribe_assoc_pair_events :topology, :layer, :underlay, :overlay

    subscribe_item_event 'topology_underlay_added_datapath', :underlay_added_datapath
    subscribe_item_event 'topology_underlay_removed_datapath', :underlay_removed_datapath
    subscribe_item_event 'topology_underlay_added_mac_range_group', :underlay_added_mac_range_group
    subscribe_item_event 'topology_underlay_removed_mac_range_group', :underlay_removed_mac_range_group

    def initialize(*args)
      begin
        info log_format("initalizing on node '#{DCell.me.id}'")
      rescue Celluloid::DeadActorError => e
        warn log_format("initalizing with dead actor")
      end

      super
    end

    def do_initialize
      info log_format('loading all topologies')

      # TODO: Redo this so that we poke node_api to send created_item
      # events while in a transaction.

      mw_class.batch.dataset.all.commit.each { |item_map|
        publish(TOPOLOGY_CREATED_ITEM, item_map)
      }

      info log_format('finished loading topologies')
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
      when :id, :uuid
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
      item_class =
        case item_map.mode
        when MODE_SIMPLE_OVERLAY then Topologies::SimpleOverlay
        when MODE_SIMPLE_UNDERLAY then Topologies::SimpleUnderlay
        else
          return
        end

      item_class.new(vnet_info: @vnet_info, map: item_map)
    end

    #
    # Create / Delete events:
    #

    def item_post_install(item, item_map)
      MW::TopologyMacRangeGroup.dispatch_added_assocs_for_parent_id(item.id)
      MW::TopologyDatapath.dispatch_added_assocs_for_parent_id(item.id)
      MW::TopologyLayer.dispatch_added_assocs_for_parent_id(item.id)
      MW::TopologyNetwork.dispatch_added_assocs_for_parent_id(item.id)
      MW::TopologySegment.dispatch_added_assocs_for_parent_id(item.id)
      MW::TopologyRouteLink.dispatch_added_assocs_for_parent_id(item.id)
    end

    # item created in db on queue 'item.id'
    def created_item(params)
      return if internal_detect_by_id(params)

      internal_new_item(mw_class.new(params))
    end

  end
end
