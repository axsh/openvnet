# -*- coding: utf-8 -*-

require 'celluloid'

module Vnet::Core

  class NetworkManager < Vnet::Core::Manager
    include Vnet::UpdateItemStates
    include Vnet::Constants::Network

    #
    # Events:
    #
    event_handler_default_drop_all
    
    # Networks have no created item event as they always get loaded
    # when used by other managers.
    subscribe_event NETWORK_INITIALIZED, :load_item
    subscribe_event NETWORK_UNLOAD_ITEM, :unload_item
    subscribe_event NETWORK_DELETED_ITEM, :unload_item

    subscribe_event NETWORK_UPDATE_ITEM_STATES, :update_item_states

    def initialize(*args)
      super
      @interface_ports = {}
      @interface_networks = {}
    end

    #
    # Interfaces:
    #

    def set_interface_port(interface_id, port)
      @interface_ports[interface_id] = port
      networks = @interface_networks[interface_id]

      add_item_ids_to_update_queue(networks) if networks
    end

    def clear_interface_port(interface_id)
      port = @interface_ports.delete(interface_id) || return
      networks = @interface_networks[interface_id]

      add_item_ids_to_update_queue(networks) if networks
    end

    def insert_interface_network(interface_id, network_id)
      networks = @interface_networks[interface_id] ||= []
      return if networks.include? network_id

      networks << network_id
      add_item_id_to_update_queue(network_id) if @interface_ports[interface_id]
    end

    def remove_interface_network(interface_id, network_id)
      networks = @interface_networks[interface_id] || return
      return unless networks.delete(network_id)

      add_item_id_to_update_queue(network_id) if @interface_ports[interface_id]
    end

    # TODO: Clear port from port manager.
    def remove_interface_from_all(interface_id)
      networks = @interface_networks.delete(interface_id)
      port = @interface_ports.delete(interface_id)

      return unless networks && port

      add_item_ids_to_update_queue(networks)
    end

    #
    # Internal methods:
    #

    private

    #
    # Specialize Manager:
    #

    def mw_class
      MW::Network
    end

    def initialized_item_event
      NETWORK_INITIALIZED
    end

    def item_unload_event
      NETWORK_UNLOAD_ITEM
    end

    def update_item_states_event
      NETWORK_UPDATE_ITEM_STATES
    end

    def match_item_proc_part(filter_part)
      filter, value = filter_part

      case filter
      when :id, :uuid, :network_mode, :network_type
        proc { |id, item| value == item.send(filter) }
      else
        raise NotImplementedError, filter
      end
    end

    def query_filter_from_params(params)
      filter = []
      filter << {id: params[:id]} if params.has_key? :id
      filter << {network_mode: params[:network_mode]} if params.has_key? :network_mode
      filter
    end

    def item_initialize(item_map)
      item_class =
        case item_map.network_mode
        when MODE_INTERNAL then Networks::Internal
        when MODE_PHYSICAL then Networks::Physical
        when MODE_VIRTUAL  then Networks::Virtual
        else
          error log_format("unknown network mode #{item_map.network_mode}")
          return nil
        end

      item_class.new(dp_info: @dp_info, map: item_map)
    end

    #
    # Create / Delete events:
    #

    def item_post_install(item, item_map)
      add_item_id_to_update_queue(item.id)

      @dp_info.active_network_manager.publish(ACTIVE_NETWORK_ACTIVATE,
                                              id: [:network, item.id])
      @dp_info.datapath_manager.publish(ACTIVATE_NETWORK_ON_HOST,
                                        id: :network,
                                        network_id: item.id)
      @dp_info.route_manager.publish(ROUTE_ACTIVATE_NETWORK,
                                     id: :network,
                                     network_id: item.id)

      @dp_info.interface_port_manager.load_simulated_on_network_id(item.id)
    end

    def item_pre_uninstall(item)
      @dp_info.active_network_manager.publish(ACTIVE_NETWORK_DEACTIVATE,
                                              id: [:network, item.id])
      @dp_info.datapath_manager.publish(DEACTIVATE_NETWORK_ON_HOST,
                                        id: :network,
                                        network_id: item.id)
      @dp_info.route_manager.publish(ROUTE_DEACTIVATE_NETWORK,
                                     id: :network,
                                     network_id: item.id)
    end

    # Requires queue ':update_item_states'
    def update_item_state(item)
      item.update_flows(port_numbers_on_network(item.id))
    end

    #
    # Helper methods:
    #

    def port_numbers_on_network(network_id)
      port_numbers = []

      @interface_networks.each { |interface_id, networks|
        next unless networks.include? network_id
        
        port_numbers << (@interface_ports[interface_id] || next)
      }

      port_numbers
    end

  end

end
