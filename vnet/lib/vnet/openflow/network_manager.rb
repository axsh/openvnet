# -*- coding: utf-8 -*-

require 'celluloid'

module Vnet::Openflow

  class NetworkManager < Manager
    include Celluloid::Logger
    include Vnet::Constants::Openflow
    include Vnet::Event::Dispatchable

    def networks(params = {})
      @items.select { |key,nw|
        result = true
        result = result && (nw.network_type == params[:network_type]) if params[:network_type]
      }.map { |key,nw|
        item_to_hash(nw)
      }
    end

    def update_all_flows
      @items.dup.each { |key,network|
        debug log_format('updating flows for', "uuid:#{network.uuid}")
        network.update_flows
      }
      nil
    end

    # Handle this internally.
    def remove(network_id)
      network = @items.delete(network_id)

      if network.nil?
        info log_format('could not find network to remove', "id:#{network_id}")
        return
      end

      if !network.ports.empty?
        info log_format('network still has active ports, and can\'t be removed',
                        "network:#{network.uuid}/#{network.id}")
        return
      end

      network.uninstall

      @datapath.dc_segment_manager.async.remove_network_id(network_id)
    end

    def add_port(params)
      network = item_by_params(params)
      return nil if network.nil?

      network.add_port(port_number: params[:port_number],
                       port_mode: params[:port_mode])
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

    #
    # Event handlers:
    #

  end

end
