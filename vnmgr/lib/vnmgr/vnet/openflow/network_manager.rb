# -*- coding: utf-8 -*-

require 'celluloid'

module Vnmgr::VNet::Openflow

  class NetworkManager
    include Celluloid::Logger

    attr_reader :datapath
    attr_reader :networks

    def initialize(dp)
      @datapath = dp
      @networks = {}
    end

    def network_by_uuid(network_uuid)
      old_network = network_by_uuid_direct(network_uuid)
      return old_network if old_network

      network = nil
      network_map = MW::Network[network_uuid]

      old_network = network_by_uuid_direct(network_uuid)
      return old_network if old_network

      case network_map.network_mode
      when 'physical'
        network = NetworkPhysical.new(self.datapath, network_map)
      when 'virtual'
        network = NetworkVirtual.new(self.datapath, network_map)
      else
        raise("Unknown network type.")
      end

      dp_map = M::Datapath[:dpid => ("0x%016x" % @datapath.datapath_id)]
      raise("Could not find datapath id: 0x%016x" % @datapath.datapath_id) unless dp_map

      dp_network_map = dp_map.batch.datapath_networks_dataset.where(:network_id => network_map.id).first.commit
      network.set_datapath_of_bridge(dp_map, dp_network_map, false)

      old_network = network_by_uuid_direct(network_uuid)
      return old_network if old_network

      @networks[network.network_id] = network

      network.install
      network.update_flows

      network_map.batch.network_services.commit(:fill => :vif).each { |service|
        network.add_service(service)
      }

      @datapath.switch.dc_segment_manager.prepare_network(network_map.id, dp_map)
      @datapath.switch.tunnel_manager.prepare_network(network_map.id, dp_map)

      network
    end

    def network_by_uuid_direct(network_uuid)
      network = @networks.find { |nw| nw[1].uuid == network_uuid }
      network && network[1]
    end

    def update_all_flows
      @networks.dup.each { |key,network|
        debug "network_manager: updating flows for: #{network.uuid}"
        network.update_flows
      }
    end

    def remove(network)
      if !network.ports.empty?
        info "network_manager: network still has active ports, and can't be removed."
        return
      end

      if @networks.delete(network.network_id).nil?
        info "network_manager: could not find network to remove: #{network.uuid}"
        return
      end

      network.uninstall
    end

  end

end
