# -*- coding: utf-8 -*-

module Vnet::Services

  class TopologyManager < Vnet::Manager
    include Vnet::Constants::Topology
    include Vnet::Constants::Interface

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
      item_class =
        case item_map.mode
        when MODE_SIMPLE_OVERLAY then Topologies::SimpleOverlay
        else
          return
        end

      item_class.new(dp_info: @dp_info, map: item_map)
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

    #
    # Network events:
    #

    # Queue [:network, network.id]

    def network_activated(params)
      debug log_format("network_activated", params.inspect)

      # Add a quick hack that bypasses topology just to test out dp_nw
      # creation.

      network_id = params[:id][1]
      datapath_id = params[:datapath_id]

      if has_datapath_network?(datapath_id, network_id)
        debug log_format("network_activated found existing datapath_network",
                         "datapath_id:#{datapath_id} network_id:#{network_id}")
        return
      end

      interface = get_a_host_interface(params[:datapath_id])

      if interface.nil?
        debug log_format("network_activated could not find host interface",
                         "datapath_id:#{datapath_id} network_id:#{network_id}")
        return
      end

      dp_nw = MW::DatapathNetwork.create(datapath_id: datapath_id,
                                         network_id: network_id,
                                         interface_id: interface.id)
      
      if dp_nw
        debug log_format("network_activated created datapath_network",
                         "datapath_id:#{datapath_id} network_id:#{network_id} interface_id:#{interface.id}")
      else
        info log_format("network_activated failed to create datapath_network",
                        "datapath_id:#{datapath_id} network_id:#{network_id} interface_id:#{interface.id}")
      end
    end

    def network_deactivated(params)
      debug log_format("network deactivated", params)
    end

    def has_datapath_network?(datapath_id, network_id)
      dp_nw = MW::DatapathNetwork.dataset.where(datapath_id: datapath_id, network_id: network_id).first

      return !dp_nw.nil?
    end

    def get_a_host_interface(datapath_id)
      interface_port = MW::InterfacePort.dataset.where(datapath_id: datapath_id,
                                                       interface_mode: MODE_HOST).first

      # debug log_format("get_a_host_interface", interface_port.inspect)

      interface = interface_port.interface

      # debug log_format("get_a_host_interface", interface.inspect)

      interface
    end

  end

end
