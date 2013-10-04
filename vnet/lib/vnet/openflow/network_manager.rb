# -*- coding: utf-8 -*-

require 'celluloid'

module Vnet::Openflow

  class NetworkManager < Manager
    include Celluloid::Logger
    include Vnet::Constants::Openflow
    include Vnet::Event::Dispatchable

    #
    # Interfaces:
    #

    def update_interface(params)
      case params[:event]
      when :remove_all
        @items.each { |id, item| item.remove_interface(params) }
        return nil
      when :update_all
        # @items.each { |id, item| item.update_interface(params) }
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
      @items.dup.each { |key,network|
        debug log_format("updating flows for #{network.uuid}/#{network.id}")
        network.update_flows
      }
      nil
    end

    #
    # Events:
    #

    def handle_event(params)
      debug log_format("handle event #{params[:event]}", "#{params.inspect}")

      item = @items[:target_id]

      case params[:event]
      when :removed
        return nil if item
        # Check if needed.
      end

      nil
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} network_manager: #{message}" + (values ? " (#{values})" : '')
    end

    #
    # Specialize Manager:
    #

    def match_item?(item, params)
      return false if params[:id] && params[:id] != item.id
      return false if params[:uuid] && params[:uuid] != item.uuid

      # Clean up use of this parameter.
      return false if params[:network_type] && params[:network_type] != item.network_type
      return false if params[:network_mode] && params[:network_mode] != item.network_type
      true
    end

    def network_initialize(mode, item_map)
      case mode
      when :physical then Networks::Physical.new(@dp_info, item_map)
      when :virtual then Networks::Virtual.new(@dp_info, item_map)
      else
        error log_format('unknown network type',
                         "network_type:#{item_map.network_mode}")
        return nil
      end
    end

    def select_item(filter)
      # Using fill for ip_leases/ip_addresses isn't going to give us a
      # proper event barrier.
      MW::Network.batch[filter].commit
    end

    def create_item(item_map, params)
      network = network_initialize(item_map.network_mode.to_sym, item_map)
      @items[network.id] = network

      if @datapath_id.nil?
        error log_format('datapath information not loaded')
        return network
      end

      dpn_item_map = MW::DatapathNetwork[datapath_id: @datapath_id, network_id: item_map.id]

      network.set_datapath_of_bridge(dp_map, dpn_item_map, false)

      network.install
      network.update_flows

      # TODO: Refactor this to only take the network id, and use that
      # to populate service manager.
      item_map.batch.network_services.commit.each { |service_map|
        @dp_info.service_manager.async.item(id: service_map.id)
      }

      @dp_info.datapath_manager.async.update_network(event: :active,
                                                     network_id: network.id)
      @dp_info.dc_segment_manager.async.prepare_network(item_map, dp_map)
      @dp_info.tunnel_manager.async.prepare_network(item_map, dp_map)
      @dp_info.route_manager.async.prepare_network(item_map, dp_map)

      dispatch_event("network/added",
                     network_id: network.id,
                     dpid: @dpid)
      network
    end

    def delete_item(item)
      if_port = item.interfaces.detect { |id, interface|
        interface.port_number
      }

      if if_port
        info log_format('network still has active ports, and can\'t be removed',
                        "#{network.uuid}/#{network.id}")
        return item
      end

      @items.delete(item.id)

      item.uninstall

      @dp_info.dc_segment_manager.async.remove_network_id(item.id)
      @dp_info.tunnel_manager.async.delete_tunnel_port(item.id, @dpid)

      dispatch_event("network/deleted",
                     id: item.id,
                     dpid: @dpid)

      item
    end

    #
    # Event handlers:
    #

  end

end
