# -*- coding: utf-8 -*-

require 'celluloid'

module Vnet::Openflow

  class NetworkManager < Vnet::Manager

    #
    # Events:
    #
    
    # Networks have no created item event as they always get loaded
    # when used by other managers.

    subscribe_event NETWORK_INITIALIZED, :install_item
    subscribe_event NETWORK_DELETED_ITEM, :unload_item

    # DEPRECATE
    def networks(params = {})
      @items.select { |key,nw|
        result = true
        result = result && (nw.network_type == params[:network_type]) if params[:network_type]
      }.map { |key,nw|
        item_to_hash(nw)
      }
    end

    #
    # Interfaces:
    #

    def update_interface(params)
      case params[:event]
      when :remove_all
        params = params.merge(no_update: true)
        @items.values.select do |item|
          item.remove_interface(params)
        end.each do |item|
          item.update_flows
        end
        return nil
      when :update_all
        params = params.merge(no_update: true)
        @items.values.select do |item|
          item.update_interface(params)
        end.each do |item|
          item.update_flows
        end
        return nil
      end

      item = item_by_params(params)

      return nil if item.nil?
      return nil if params[:interface_id].nil?

      case params[:event]
      when :insert then item.insert_interface(params)
      when :remove then item.remove_interface(params)
      when :update then item.update_interface(params)
      end

      #   if network.ports.empty?
      #   end

      nil
    end

    #
    # Obsolete:
    #

    def update_all_flows
      @items.dup.each { |key, item|
        debug log_format("updating flows for #{item.uuid}/#{item.id}")
        item.update_flows
      }
      nil
    end

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

    def item_initialize(item_map, params)
      item_class =
        case item_map.network_mode
        when 'physical' then Networks::Physical
        when 'virtual'  then Networks::Virtual
        else
          error log_format('unknown network type',
                           "network_mode:#{item_map.network_mode}")
          return nil
        end

      item_class.new(@dp_info, item_map)
    end

    def select_item(filter)
      # Using fill for ip_leases/ip_addresses isn't going to give us a
      # proper event barrier.
      MW::Network.batch[filter].commit(fill: :network_services)
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
      item.update_flows

      # TODO: Publish...
      @dp_info.datapath_manager.update(event: :activate_network,
                                       network_id: item.id)

      # TODO: Load simulated interfaces instead, use those to load up services.
      item_map.network_services.each { |service_map|
        @dp_info.service_manager.async.item(id: service_map.id)
      }

      @dp_info.route_manager.publish(Vnet::Event::ROUTE_ACTIVATE_NETWORK,
                                     id: :network,
                                     network_id: item.id)
    end

    # unload item on queue 'item.id'
    def unload_item(params)
      item = @items.delete(item[:id]) || return
      item.try_uninstall

      @dp_info.datapath_manager.update(event: :deactivate_network,
                                       network_id: item.id)

      @dp_info.route_manager.publish(Vnet::Event::ROUTE_DEACTIVATE_NETWORK,
                                     id: :network,
                                     network_id: item.id)

      debug log_format("unloaded network #{item.uuid}/#{item.id}")
    end

    #
    # Event handlers:
    #

  end

end
