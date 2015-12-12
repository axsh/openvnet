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

    subscribe_event TOPOLOGY_CREATE_DP_NW, :create_dp_nw

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

      item_class.new(dp_info: @dp_info, map: item_map)
    end

    def log_format_dp_nw(message, datapath_id, network_id)
      log_format(message, "datapath_id:#{datapath_id} network_id:#{network_id}")
    end

    def log_format_dp_nw_if(message, datapath_id, network_id, interface_id)
      log_format(message, "datapath_id:#{datapath_id} network_id:#{network_id} interface_id:#{interface_id}")
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

        debug log_format_dp_nw("network activated", datapath_id, network_id)

        if has_datapath_network?(datapath_id, network_id)
          debug log_format_dp_nw("found existing datapath_network", datapath_id, network_id)
          return
        end

      rescue Vnet::ParamError => e
        handle_param_error(e)
      end

      item_id = find_id_using_tp_nw(datapath_id, network_id) || return

      if internal_retrieve(id: item_id).nil?
        warn log_format_dp_nw("could not retrieve topology associated with network", datapath_id, network_id)
        return
      end

      event_options = {
        id: item_id,
        network_id: network_id,
        datapath_id: datapath_id
      }

      publish(TOPOLOGY_CREATE_DP_NW, event_options)
    end

    # TOPOLOGY_NETWORK_DEACTIVATED on queue [:network, network.id]
    def network_deactivated(params)
      debug log_format("network deactivated", params)
    end

    # TOPOLOGY_CREATE_DP_NW on queue 'item.id'
    def create_dp_nw(params)
      debug log_format("creating datapath_network", params)

      item = internal_detect_by_id(params) || return

      begin
        item.create_dp_nw(params)
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
      filter = {
        network_id: network_id
      }

      # TODO: Should keep local tp_nw list.
      tp_nw = MW::TopologyNetwork.batch.dataset.where(filter).first.commit
      
      if tp_nw.nil? || tp_nw.topology_id.nil?
        warn log_format_dp_nw("network not associated with a topology", datapath_id, network_id)
        return
      end

      tp_nw.topology_id
    end

    def has_datapath_network?(datapath_id, network_id)
      filter = {
        datapath_id: datapath_id,
        network_id: network_id
      }

      !MW::DatapathNetwork.batch.dataset.where(filter).first.commit.nil?
    end

  end

end
