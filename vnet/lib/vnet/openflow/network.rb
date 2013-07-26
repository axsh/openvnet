# -*- coding: utf-8 -*-

module Vnet::Openflow

  class Network
    include Celluloid::Logger
    include FlowHelpers

    attr_reader :datapath
    attr_reader :network_id
    attr_reader :network_number
    attr_reader :uuid
    attr_reader :datapath_of_bridge

    attr_reader :ports
    attr_reader :service_cookies

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
      @service_cookies = {}

      @cookie = @network_id | (COOKIE_PREFIX_NETWORK << COOKIE_PREFIX_SHIFT)
      @ipv4_network = IPAddr.new(network_map.ipv4_network, Socket::AF_INET)
      @ipv4_prefix = network_map.ipv4_prefix
    end

    def broadcast_mac_addr
      self.datapath_of_bridge && self.datapath_of_bridge[:broadcast_mac_addr]
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
      # info "network(#{self.uuid}): set_datapath_of_bridge: dpn_map:#{dpn_map.inspect}"

      @datapath_of_bridge = {
        :uuid => datapath_map.uuid,
        :display_name => datapath_map.display_name,
        :ipv4_address => datapath_map.ipv4_address,
        :datapath_id => datapath_map.dpid,
      }

      if dpn_map
        @datapath_of_bridge[:broadcast_mac_addr] = Trema::Mac.new(dpn_map.broadcast_mac_addr)
      else
        error "network(#{@uuid}): no datapath associated with network."
      end
    end

    def add_service(service_map)
      if @service_cookies[service_map.uuid]
        error "network(#{@uuid}): service already exists '#{service_map.uuid}'"
        return
      end

      translated_map = {
        :datapath => self.datapath,
        :network => self, # Deprecate...
        :network_id => @network_id,
        :network_uuid => @network_uuid,
        :vif_uuid => service_map.vif.uuid,
        :service_mac => Trema::Mac.new(service_map.vif.mac_addr),
        :service_ipv4 => IPAddr.new(service_map.vif.ipv4_address, Socket::AF_INET)
      }

      info "network(#{@uuid}): creating service '#{service_map.display_name}'"

      service = case service_map.display_name
                when 'dhcp'   then Vnet::Openflow::Services::Dhcp.new(translated_map)
                when 'router' then Vnet::Openflow::Services::Router.new(translated_map)
                else
                  error "network(#{@uuid}): failed to create service '#{service_map.uuid}'"
                  return
                end

      pm = @datapath.switch.packet_manager

      cookie = pm.insert(service,
                         nil,
                         service_map.id | (COOKIE_PREFIX_SERVICE << COOKIE_PREFIX_SHIFT))

      if cookie.nil?
        error "network(#{@uuid}): aborting creation of services '#{service_map.uuid}'"
        return
      end

      @service_cookies[service_map.uuid] = cookie
      
      pm.dispatch(:arp)  { |key, handler| handler.insert_vif(service_map.vif.uuid, self, service_map.vif) }
      pm.dispatch(:icmp) { |key, handler| handler.insert_vif(service_map.vif.uuid, self, service_map.vif) }
    end

    def uninstall
      info "network(#{@uuid}): removing flows"
      
      pm = self.datapath.switch.packet_manager

      @datapath.del_cookie(@cookie)

      @service_cookies.each { |uuid,cookie|
        pm.remove(cookie)
        pm.dispatch(:arp)  { |key, handler| handler.remove_vif(service.vif_uuid) }
        pm.dispatch(:icmp) { |key, handler| handler.remove_vif(service.vif_uuid) }
      }
    end

  end

end
