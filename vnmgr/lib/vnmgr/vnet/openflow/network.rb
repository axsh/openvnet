# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  class Network
    include Constants
    include Celluloid::Logger

    attr_reader :datapath
    attr_reader :network_id
    attr_reader :network_number
    attr_reader :uuid
    attr_reader :datapath_of_bridge

    attr_reader :ports
    attr_reader :services

    attr_reader :cookie
    attr_reader :ipv4_network
    attr_reader :ipv4_prefix

    def initialize(dp, network_map)
      @datapath = dp
      @uuid = network_map.uuid
      @network_id = network_map.network_id
      @network_number = network_map.network_id
      @datapath_of_bridge = nil

      @ports = {}
      @services = {}

      @cookie = @network_id | (0x4 << 48)
      @ipv4_network = IPAddr.new(network_map.ipv4_network, Socket::AF_INET)
      @ipv4_prefix = network_map.ipv4_prefix
    end

    def metadata_flags(flags)
      { :metadata => flags, :metadata_mask => flags }
    end

    def metadata_n(nw = self.network_number)
      { :metadata => nw << Constants::METADATA_NETWORK_SHIFT,
        :metadata_mask => Constants::METADATA_NETWORK_MASK
      }
    end

    def metadata_p(port = 0x0)
      { :metadata => port,
        :metadata_mask => Constants::METADATA_PORT_MASK
      }
    end

    def metadata_pn(port = 0x0)
      { :metadata => (self.network_number << Constants::METADATA_NETWORK_SHIFT) | port,
        :metadata_mask => (Constants::METADATA_PORT_MASK | Constants::METADATA_NETWORK_MASK)
      }
    end

    def add_port(port, should_update)
      raise("Port already added to a network.") if port.network || @ports[port.port_number]

      @ports[port.port_number] = port
      port.network = self

      update_flows if should_update
    end

    def del_port(port, should_update)
      deleted_port = @ports.delete(port.port_number)
      update_flows if should_update

      raise("Port not added to this network.") if port.network != self || deleted_port.nil?

      port.network = nil
    end

    def set_datapath_of_bridge(datapath_map, dpn_map, should_update)
      @datapath_of_bridge = {
        :uuid => datapath_map.uuid,
        :display_name => datapath_map.display_name,
        :ipv4_address => datapath_map.ipv4_address,
        :datapath_id => datapath_map.datapath_id,
        :broadcast_mac_addr => dpn_map ? Trema::Mac.new(dpn_map.broadcast_mac_addr) : nil,
      }

      # p "Setting the datapath of network: network:#{self.uuid} datapath:#{datapath.inspect}"

      update_flows if should_update
    end

    def add_service(service_map)
      raise("Service already added to network.") if @services[service_map.uuid]

      service = nil

      translated_map = {
        :datapath => self.datapath,
        :network => self,
        :service_mac => Trema::Mac.new(service_map.vif_map[:mac_addr]),
        :service_ipv4 => IPAddr.new(service_map.vif_map[:ipv4_address], Socket::AF_INET)
      }

      service = case service_map.display_name
                when 'dhcp'
                  Vnmgr::VNet::Services::Dhcp.new(translated_map)
                else
                  error "Failed to create service: #{service_map.uuid}"
                  return
                end

      @services[service_map.uuid] = service
      @datapath.switch.packet_manager.async.insert(service)
    end

    def uninstall
      info "network #{self.uuid}: Removing flows."
      
      pm = self.datapath.switch.packet_manager

      @datapath.del_cookie(@cookie)
      @services.each { |uuid,service| pm.async.remove(service) }
    end

  end

end
