# -*- coding: utf-8 -*-

require 'celluloid'

module Vnet::Openflow

  class NetworkManager < Vnet::Manager

    include Vnet::Constants::Network

    #
    # Events:
    #
    
    # Networks have no created item event as they always get loaded
    # when used by other managers.

    subscribe_event NETWORK_INITIALIZED, :install_item
    subscribe_event NETWORK_DELETED_ITEM, :unload_item

    subscribe_event NETWORK_UPDATE_NETWORKS, :update_networks

    def initialize(*args)
      super
      @interface_ports = {}
      @interface_networks = {}

      @update_networks = {}
    end

    #
    # Interfaces:
    #

    def set_interface_port(interface_id, port)
      @interface_ports[interface_id] = port
      networks = @interface_networks[interface_id]

      add_network_ids_to_update_networks(networks) if networks
    end

    def clear_interface_port(interface_id)
      port = @interface_ports.delete(interface_id) || return
      networks = @interface_networks[interface_id]

      add_network_ids_to_update_networks(networks) if networks
    end

    def insert_interface_network(interface_id, network_id)
      networks = @interface_networks[interface_id] ||= []
      return if networks.include? network_id

      networks << network_id
      add_network_id_to_update_networks(network_id) if @interface_ports[interface_id]
    end

    def remove_interface_network(interface_id, network_id)
      networks = @interface_networks[interface_id] || return
      return unless networks.delete(network_id)

      add_network_id_to_update_networks(network_id) if @interface_ports[interface_id]
    end

    # TODO: Clear port from port manager.
    def remove_interface_from_all(interface_id)
      networks = @interface_networks.delete(interface_id)
      port = @interface_ports.delete(interface_id)

      return unless networks && port

      add_network_ids_to_update_networks(networks)
    end

    #
    # Obsolete:
    #

    def network_id_by_mac(mac_address)
      network_map = MW::Network.batch.find_by_mac_address(mac_address).commit
      debug log_format("network_id_by_mac : mac_address => #{Trema::Mac.new(mac_address)}")
      debug log_format("network_id_by_mac : network_map => #{network_map.inspect}")
      return network_map && network_map.id
    end

    #
    # Internal methods:
    #

    private

    #
    # Specialize Manager:
    #

    def initialized_item_event
      NETWORK_INITIALIZED
    end

    def match_item?(item, params)
      return false if params[:id] && params[:id] != item.id
      return false if params[:uuid] && params[:uuid] != item.uuid

      # Clean up use of this parameter.
      return false if params[:network_type] && params[:network_type] != item.network_type
      return false if params[:network_mode] && params[:network_mode] != item.network_type
      true
    end

    def select_filter_from_params(params)
      return nil if params.has_key?(:uuid) && params[:uuid].nil?

      filters = []
      filters << {id: params[:id]} if params.has_key? :id

      create_batch(MW::Network.batch, params[:uuid], filters)
    end

    def item_initialize(item_map, params)
      item_class =
        case item_map.network_mode
        when MODE_PHYSICAL then Networks::Physical
        when MODE_VIRTUAL  then Networks::Virtual
        else
          error log_format('unknown network type',
                           "network_mode:#{item_map.network_mode}")
          return nil
        end

      item_class.new(@dp_info, item_map)
    end

    #
    # Create / Delete events:
    #

    # NETWORK_INITIALIZED on queue 'item.id'
    def install_item(params)
      item_map = params[:item_map] || return
      item = @items[item_map.id] || return

      debug log_format("install #{item_map.uuid}/#{item_map.id}")

      item.try_install

      add_network_id_to_update_networks(item.id)

      @dp_info.datapath_manager.publish(ACTIVATE_NETWORK_ON_HOST,
                                        id: :network,
                                        network_id: item.id)
      @dp_info.route_manager.publish(ROUTE_ACTIVATE_NETWORK,
                                     id: :network,
                                     network_id: item.id)

      @dp_info.interface_manager.load_simulated_on_network_id(item.id)
    end

    # unload item on queue 'item.id'
    def unload_item(params)
      item = @items.delete(item[:id]) || return
      item.try_uninstall

      @dp_info.datapath_manager.publish(DEACTIVATE_NETWORK_ON_HOST,
                                        id: :network,
                                        network_id: item.id)
      @dp_info.route_manager.publish(ROUTE_DEACTIVATE_NETWORK,
                                     id: :network,
                                     network_id: item.id)

      debug log_format("unloaded network #{item.uuid}/#{item.id}")
    end

    #
    # Event handlers:
    #

    # NETWORK_UPDATE_NETWORKS on queue ':update_networks'
    def update_networks(params)
      while !@update_networks.empty?
        network_ids = @update_networks.keys

        info log_format("updating network flows", network_ids.to_s)

        network_ids.each { |network_id|
          next unless @update_networks.delete(network_id)

          update_network_id(network_id)
        }

        # Sleep for 10 msec in order to poll up more potential changes
        # to the same networks.
        sleep(0.01)
      end
    end

    # Requires queue ':update_networks'
    def update_network_id(network_id)
      item = @items[network_id] || return
      return unless item.installed

      item.update_flows(port_numbers_on_network(network_id))
    end

    #
    # Helper methods:
    #

    def add_network_id_to_update_networks(network_id)
      should_publish = @update_networks.empty?
      @update_networks[network_id] = true

      should_publish && publish(NETWORK_UPDATE_NETWORKS, id: :update_networks)
    end

    def add_network_ids_to_update_networks(network_ids)
      should_publish = @update_networks.empty?

      network_ids.select { |network_id|
        @update_networks[network_id].nil?
      }.each { |network_id|
        @update_networks[network_id] = true
      }

      should_publish && publish(NETWORK_UPDATE_NETWORKS, id: :update_networks)
    end

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
