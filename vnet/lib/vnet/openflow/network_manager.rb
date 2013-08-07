# -*- coding: utf-8 -*-

require 'celluloid'

module Vnet::Openflow

  class NetworkManager
    include Celluloid::Logger
    include Vnet::Constants::Openflow
    include Vnet::Event::Dispatchable

    def initialize(dp)
      @datapath = dp
      @networks = {}

      @dpid = @datapath.dpid
      @dpid_s = "0x%016x" % @datapath.dpid
    end

    def network_by_id(network_id, dynamic_load = true)
      nw_to_hash(nw_by_id(network_id, dynamic_load))
    end

    def network_by_uuid(network_uuid, dynamic_load = true)
      nw_to_hash(nw_by_uuid(network_uuid, dynamic_load))
    end

    def network_by_params(params, dynamic_load = true)
      nw_to_hash(nw_by_params(params, dynamic_load))
    end

    def networks(params = {})
      @networks.select { |key,nw|
        result = true
        result = result && (nw.network_type == params[:network_type]) if params[:network_type]
      }.map { |key,nw|
        nw_to_hash(nw)
      }
    end

    def update_all_flows
      @networks.dup.each { |key,network|
        debug log_format('updating flows for', "uuid:#{network.uuid}")
        network.update_flows
      }
      nil
    end

    # Handle this internally.
    def remove(network_id)
      network = @networks.delete(network_id)

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
      network = nw_by_params(params, true)
      return nil if network.nil?

      network.add_port(port_number: params[:port_number],
                       port_mode: params[:port_mode])
      nw_to_hash(network)
    end

    def del_port_number(network_id, port_number)
      network = @networks[network_id]
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
      "network_manager: #{message} (dpid:#{@dpid_s}#{values ? ' ' : ''}#{values})"
    end

    def nw_to_hash(network)
      network && network.to_hash
    end

    def nw_by_id(network_id, dynamic_load)
      old_network = @networks[network_id]
      return old_network if old_network || !dynamic_load

      # TODO: Don't load the same network id/uuid for multiple
      # simultaneous callers.
      network_map = MW::Network[:id => network_id]

      old_network = @networks[network_id]
      return old_network if old_network

      create_network(network_map)
    end

    def nw_by_uuid(network_uuid, dynamic_load)
      old_network = nw_by_uuid_direct(network_uuid)
      return old_network if old_network || !dynamic_load

      network_map = MW::Network[network_uuid]

      old_network = nw_by_uuid_direct(network_uuid)
      return old_network if old_network

      create_network(network_map)
    end

    def nw_by_uuid_direct(network_uuid)
      network = @networks.find { |nw| nw[1].uuid == network_uuid }
      network && network[1]
    end

    def nw_by_params(params, dynamic_load)
      case
      when params[:network_id]
        return nw_by_id(params[:network_id], dynamic_load)
      when params[:network_uuid]
        return nw_by_uuid(params[:network_uuid], dynamic_load)
      else
        raise("Missing network id/uuid parameter.")
      end
    end

    def create_network(network_map)
      case network_map.network_mode
      when 'physical'
        network = Networks::Physical.new(@datapath, network_map)
      when 'virtual'
        network = Networks::Virtual.new(@datapath, network_map)
      else
        error log_format('unknown network type',
                         "network_type:#{network_map.network_mode}")
        return nil
      end
      
      dp_map = MW::Datapath[:dpid => @dpid_s]

      if dp_map.nil?
        error log_format('could not find datapath id in database')
        return nil
      end

      dp_network_map = dp_map.batch.datapath_networks_dataset.where(:network_id => network_map.id).first.commit

      network.set_datapath_of_bridge(dp_map, dp_network_map, false)

      old_network = @networks[network_map.id]
      return old_network if old_network

      @networks[network.network_id] = network

      network.install
      network.update_flows

      network_map.batch.network_services.commit(:fill => :vif).each { |service_map|
        network.add_service(service_map) if service_map.vif.mode == 'simulated'
      }

      @datapath.dc_segment_manager.async.prepare_network(network_map, dp_map)
      @datapath.tunnel_manager.async.prepare_network(network_map, dp_map)
      @datapath.route_manager.async.prepare_network(network_map, dp_map)

      dispatch_event("network/added",
                     network_id: network.network_id,
                     dpid: @dpid)
      network
    end

  end

end
