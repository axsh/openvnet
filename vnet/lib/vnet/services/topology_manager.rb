# -*- coding: utf-8 -*-

module Vnet::Services

  class TopologyManager < Vnet::Manager
    include Vnet::Constants::Topology

    #
    # Events:
    #
    # event_handler_default_drop_all

    subscribe_event TOPOLOGY_INITIALIZED, :load_item
    subscribe_event TOPOLOGY_UNLOAD_ITEM, :unload_item
    subscribe_event TOPOLOGY_CREATED_ITEM, :created_item
    subscribe_event TOPOLOGY_DELETED_ITEM, :unload_item

    subscribe_event TOPOLOGY_NETWORK_ACTIVATED, :network_activated
    subscribe_event TOPOLOGY_NETWORK_DEACTIVATED, :network_deactivated

    subscribe_event TOPOLOGY_SEGMENT_ACTIVATED, :segment_activated
    subscribe_event TOPOLOGY_SEGMENT_DEACTIVATED, :segment_deactivated

    subscribe_event TOPOLOGY_ROUTE_LINK_ACTIVATED, :route_link_activated
    subscribe_event TOPOLOGY_ROUTE_LINK_DEACTIVATED, :route_link_deactivated

    subscribe_event TOPOLOGY_CREATE_DP_NW, :create_dp_nw
    subscribe_event TOPOLOGY_CREATE_DP_SEG, :create_dp_seg
    subscribe_event TOPOLOGY_CREATE_DP_RL, :create_dp_rl

    # TODO: Add events for host interfaces?

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

      item_class.new(map: item_map)
    end

    #
    # Create / Delete events:
    #

    # item created in db on queue 'item.id'
    def created_item(params)
      return if internal_detect_by_id(params)

      internal_new_item(mw_class.new(params))
    end

    #
    # Network events:
    #

    # TOPOLOGY_NETWORK_ACTIVATED on queue [:network, network.id]
    def network_activated(params)
      begin
        network_id = get_param_packed_id(params)
        datapath_id = get_param_id(params, :datapath_id)

        event_options = {
          network_id: network_id,
          datapath_id: datapath_id
        }

        debug log_format_h("network activated", event_options)

        if has_datapath_network?(datapath_id, network_id)
          debug log_format_h("found existing datapath_network", event_options)
          return
        end

      rescue Vnet::ParamError => e
        handle_param_error(e)
      end

      item_id = find_id_using_tp_nw(datapath_id, network_id) || return

      event_options[:id] = item_id

      if internal_retrieve(id: item_id).nil?
        warn log_format_h("could not retrieve topology associated with network", event_options)
        return
      end

      publish(TOPOLOGY_CREATE_DP_NW, event_options)
    end

    # TOPOLOGY_NETWORK_DEACTIVATED on queue [:network, network.id]
    def network_deactivated(params)
      debug log_format_h("network deactivated", params)
    end

    # TOPOLOGY_CREATE_DP_NW on queue 'item.id'
    def create_dp_nw(params)
      debug log_format_h("creating datapath_network", params)

      item = internal_detect_by_id(params) || return

      begin
        item.create_dp_nw(params)
      rescue Vnet::ParamError => e
        handle_param_error(e)
      end
    end

    #
    # Segment events:
    #

    # TOPOLOGY_SEGMENT_ACTIVATED on queue [:segment, segment.id]
    def segment_activated(params)
      begin
        segment_id = get_param_packed_id(params)
        datapath_id = get_param_id(params, :datapath_id)

        event_options = {
          segment_id: segment_id,
          datapath_id: datapath_id
        }

        debug log_format_h("segment activated", event_options)

        if has_datapath_segment?(datapath_id, segment_id)
          debug log_format_h("found existing datapath_segment", event_options)
          return
        end

      rescue Vnet::ParamError => e
        handle_param_error(e)
      end

      item_id = find_id_using_tp_seg(datapath_id, segment_id) || return

      event_options[:id] = item_id

      if internal_retrieve(id: item_id).nil?
        warn log_format_h("could not retrieve topology associated with segment", event_options)
        return
      end

      publish(TOPOLOGY_CREATE_DP_SEG, event_options)
    end

    # TOPOLOGY_SEGMENT_DEACTIVATED on queue [:segment, segment.id]
    def segment_deactivated(params)
      debug log_format_h("segment deactivated", params)
    end

    # TOPOLOGY_CREATE_DP_SEG on queue 'item.id'
    def create_dp_seg(params)
      debug log_format_h("creating datapath_segment", params)

      item = internal_detect_by_id(params) || return

      begin
        item.create_dp_seg(params)
      rescue Vnet::ParamError => e
        handle_param_error(e)
      end
    end

    #
    # Route Link events:
    #

    # TOPOLOGY_ROUTE_LINK_ACTIVATED on queue [:route_link, route_link.id]
    def route_link_activated(params)
      begin
        route_link_id = get_param_packed_id(params)
        datapath_id = get_param_id(params, :datapath_id)

        event_options = {
          route_link_id: route_link_id,
          datapath_id: datapath_id
        }

        debug log_format_h("route_link activated", event_options)

        if has_datapath_route_link?(datapath_id, route_link_id)
          debug log_format_h("found existing datapath_route_link", event_options)
          return
        end

      rescue Vnet::ParamError => e
        handle_param_error(e)
      end

      item_id = find_id_using_tp_rl(datapath_id, route_link_id) || return

      event_options[:id] = item_id

      if internal_retrieve(id: item_id).nil?
        warn log_format_h("could not retrieve topology associated with route link", event_options)
        return
      end

      publish(TOPOLOGY_CREATE_DP_RL, event_options)
    end

    # TOPOLOGY_ROUTE_LINK_DEACTIVATED on queue [:route_link, route_link.id]
    def route_link_deactivated(params)
      debug log_format_h("route_link deactivated", params)
    end

    # TOPOLOGY_CREATE_DP_RL on queue 'item.id'
    def create_dp_rl(params)
      debug log_format_h("creating datapath_route_link", params)

      item = internal_detect_by_id(params) || return

      begin
        item.create_dp_rl(params)
      rescue Vnet::ParamError => e
        handle_param_error(e)
      end
    end

    #
    # Helper methods:
    #

    # Currently we look up the topology directly, which means we don't
    # have proper handling of changes to topologies, etc.
    def find_id_using_tp_nw(datapath_id, network_id)
      # TODO: Should keep local tp_obj list.
      tp_obj = MW::TopologyNetwork.batch.dataset.where(network_id: network_id).first.commit

      if tp_obj.nil? || tp_obj.topology_id.nil?
        warn log_format("network not associated with a topology", "datapath_id:#{datapath_id} network_id:#{network_id}")
        return
      end

      tp_obj.topology_id
    end

    def find_id_using_tp_seg(datapath_id, segment_id)
      # TODO: Should keep local tp_obj list.
      tp_obj = MW::TopologySegment.batch.dataset.where(segment_id: segment_id).first.commit

      if tp_obj.nil? || tp_obj.topology_id.nil?
        warn log_format("segment not associated with a topology", "datapath_id:#{datapath_id} segment_id:#{segment_id}")
        return
      end

      tp_obj.topology_id
    end

    def find_id_using_tp_rl(datapath_id, route_link_id)
      # TODO: Should keep local tp_obj list.
      tp_obj = MW::TopologyRouteLink.batch.dataset.where(route_link_id: route_link_id).first.commit

      if tp_obj.nil? || tp_obj.topology_id.nil?
        warn log_format("route_link not associated with a topology", "datapath_id:#{datapath_id} route_link_id:#{route_link_id}")
        return
      end

      tp_obj.topology_id
    end

    def has_datapath_network?(datapath_id, network_id)
      filter = {
        datapath_id: datapath_id,
        network_id: network_id
      }

      !MW::DatapathNetwork.batch.dataset.where(filter).first.commit.nil?
    end

    def has_datapath_segment?(datapath_id, segment_id)
      filter = {
        datapath_id: datapath_id,
        segment_id: segment_id
      }

      !MW::DatapathSegment.batch.dataset.where(filter).first.commit.nil?
    end

    def has_datapath_route_link?(datapath_id, route_link_id)
      filter = {
        datapath_id: datapath_id,
        route_link_id: route_link_id
      }

      !MW::DatapathRouteLink.batch.dataset.where(filter).first.commit.nil?
    end

  end

end
