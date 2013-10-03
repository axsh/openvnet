# -*- coding: utf-8 -*-

require 'celluloid'

module Vnet::Openflow

  class NetworkManager < Manager
    include Celluloid::Logger
    include Vnet::Constants::Openflow
    include Vnet::Event::Dispatchable

    #
    # Events:
    #
    subscribe_event :added_network # TODO Check if needed.
    subscribe_event :removed_network # TODO Check if needed.

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
      item = item_by_params(params)

      return nil if item.nil?
      return nil if params[:interface_id].nil?

      case params[:event]
      when :insert then item.insert_interface(params)
      when :remove then item.remove_interface(params)
      when :update then item.update_interface(params)
      end

      nil
    end

    #
    # Obsolete:
    #

    def update_all_flows
      @items.dup.each { |key,network|
        debug log_format("updating flows for #{network.uuid}/#{network.network_id}")
        network.update_flows
      }
      nil
    end

    def add_port(params)
      network = item_by_params(params)
      return nil if network.nil?

      network.add_port(params)
      item_to_hash(network)
    end

    def del_port_number(network_id, port_number)
      network = @items[network_id]
      return nil if network.nil?

      network.del_port_number(port_number)

      if network.ports.empty?
        remove(network)
        @datapath.tunnel_manager.delete_tunnel_port(network_id, @dpid)

        dispatch_event("network/deleted",
                       network_id: network_id,
                       dpid: @dpid)
      end
      
      nil
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dpid_s} network_manager: #{message}" + (values ? " (#{values})" : '')
    end

    def network_initialize(mode, item_map)
      case mode
      when :physical then Networks::Physical.new(@datapath, item_map)
      when :virtual then Networks::Virtual.new(@datapath, item_map)
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
      @items[network.network_id] = network

      dp_map = @datapath.datapath_map

      if dp_map.nil?
        error log_format('datapath information not found in database')
        return network
      end

      dpn_item_map = dp_map.batch.datapath_networks_dataset.where(:network_id => item_map.id).first.commit

      network.set_datapath_of_bridge(dp_map, dpn_item_map, false)

      network.install
      network.update_flows

      # TODO: Refactor this to only take the network id, and use that
      # to populate service manager.
      item_map.batch.network_services.commit.each { |service_map|
        @datapath.service_manager.item(:id => service_map.id)
      }

      @datapath.dc_segment_manager.async.prepare_network(item_map, dp_map)
      @datapath.tunnel_manager.async.prepare_network(item_map, dp_map)
      @datapath.route_manager.async.prepare_network(item_map, dp_map)

      dispatch_event("network/added",
                     network_id: network.network_id,
                     dpid: @dpid)
      network
    end

    def delete_item(item)
      if !item.ports.empty?
        info log_format('network still has active ports, and can\'t be removed',
                        "#{network.uuid}/#{network.id}")
        return item
      end

      @items.delete(item.network_id)

      item.uninstall

      @datapath.dc_segment_manager.async.remove_network_id(item.network_id)

      item
    end

    #
    # Event handlers:
    #

  end

end
