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

    subscribe_event TOPOLOGY_CREATE_DP_GENERIC, :create_dp_generic

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
        else
          return
        end

      item_class.new(dp_info: @dp_info, map: item_map)
    end

    def log_format_dn(message, datapath_id, network_id)
      log_format(message, "datapath_id:#{datapath_id} network_id:#{network_id}")
    end

    def log_format_dni(message, datapath_id, network_id, interface_id)
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

    # TODO: Queue needs to add datapath?

    # Queue [:network, network.id]

    def network_activated(params)
      debug log_format("network_activated", params.inspect)

      # Add a quick hack that bypasses topology just to test out dp_nw
      # creation.

      begin
        network_id = get_param_packed_id(params)
        datapath_id = get_param_id(params, :datapath_id)

        if has_datapath_network?(datapath_id, network_id)
          debug log_format_dn("network_activated found existing datapath_network", datapath_id, network_id)
          return
        end

      rescue Vnet::ParamError => e
        handle_param_error(e)
      end

      # TODO: Rest should be done within the context of the item,
      # using an event.
      #
      # TODO: Just need the topology_id.
      item_id = find_id_using_tp_nw(network_id, datapath_id)

      if item_id.nil?
        warn log_format_dn("network not associated with a topology", datapath_id, network_id)
        return
      end

      if internal_retrieve(id: item_id).nil?
        warn log_format_dn("could not retrieve topology associated with network", datapath_id, network_id)
        return
      end

      event_options = {
        id: item_id,
        type: :network,
        dp_generic_id: network_id,
        datapath_id: datapath_id
      }

      publish(TOPOLOGY_CREATE_DP_GENERIC, event_options)
    end

    def network_deactivated(params)
      debug log_format("network deactivated", params)
    end

    def create_dp_generic(params)
      debug log_format("create_datapath_generic", params.inspect)

      item = internal_detect_by_id(params) || return

      begin
        dp_generic_id = get_param_id(params, :dp_generic_id)
        datapath_id = get_param_id(params, :datapath_id)

        interface_id = get_a_host_interface_id(datapath_id)

        if interface_id.nil?
          warn log_format_dn("create_datapath_generic could not find host interface", datapath_id, network_id)
          return
        end

        case get_param_symbol(params, :type)
        when :network
          create_datapath_network(datapath_id, dp_generic_id, interface_id)
        else
          throw_param_error("unknown type", params, :type)
        end

      rescue Vnet::ParamError => e
        handle_param_error(e)
      end
    end

    #
    # Helper methods:
    #

    # Currently we look up the topology directly, which means we don't
    # have proper handling of changes to topologies, etc.
    def find_id_using_tp_nw(network_id, datapath_id)
      filter = {
        network_id: network_id
      }

      # TODO: Should keep local tp_nw list.
      tp_nw = MW::TopologyNetwork.batch.dataset.where(filter).first.commit
      
      debug log_format("detect_using_tp_nw XXXXXXXXXXXX", tp_nw.inspect)

      tp_nw && tp_nw.topology_id
    end

    def has_datapath_network?(datapath_id, network_id)
      filter = {
        datapath_id: datapath_id,
        network_id: network_id
      }

      !MW::DatapathNetwork.batch.dataset.where(filter).first.commit.nil?
    end

    def create_datapath_network(datapath_id, network_id, interface_id)
      create_params = {
        datapath_id: datapath_id,
        network_id: network_id,
        interface_id: interface_id
      }

      if MW::DatapathNetwork.batch.create(create_params).commit
        debug log_format_dni("created datapath_network", datapath_id, network_id, interface_id)
      else
        info log_format_dni("failed to create datapath_network", datapath_id, network_id, interface_id)
      end
    end

    #
    #
    #

    def get_a_host_interface_id(datapath_id)
      filter = {
        datapath_id: datapath_id,
        interface_mode: Vnet::Constants::Interface::MODE_HOST
      }

      interface = MW::InterfacePort.batch.dataset.where(filter).first.commit

      debug log_format("get_a_host_interface", interface.inspect)

      interface.interface_id
    end

  end

end
