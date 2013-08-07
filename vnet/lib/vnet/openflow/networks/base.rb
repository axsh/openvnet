# -*- coding: utf-8 -*-

module Vnet::Openflow::Networks

  class Base
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_reader :datapath
    attr_reader :network_id
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
      @datapath_of_bridge = nil

      @ports = {}
      @service_cookies = {}

      @cookie = @network_id | (COOKIE_PREFIX_NETWORK << COOKIE_PREFIX_SHIFT)
      @ipv4_network = IPAddr.new(network_map.ipv4_network, Socket::AF_INET)
      @ipv4_prefix = network_map.ipv4_prefix
    end

    def broadcast_mac_addr
      @datapath_of_bridge && @datapath_of_bridge[:broadcast_mac_addr]
    end

    def add_port(params)
      if @ports[params[:port_number]]
        raise("Port already added to a network.")
      end

      port = {
        # List of ip/mac addresses on this network, etc.
        :mode => params[:port_mode],
      }

      @ports[params[:port_number]] = port

      update_flows
    end

    def del_port_number(port_number)
      port = @ports.delete(port_number)

      if port.nil?
        raise("Port was not added to this network.")
      end

      update_flows
    end

    def set_datapath_of_bridge(datapath_map, dpn_map, should_update)
      # info "network(#{@uuid}): set_datapath_of_bridge: dpn_map:#{dpn_map.inspect}"

      @datapath_of_bridge = {
        :uuid => datapath_map.uuid,
        :display_name => datapath_map.display_name,
        :ipv4_address => datapath_map.ipv4_address,
        :datapath_id => datapath_map.id,
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
        :datapath => @datapath,
        :network => self, # Deprecate...
        :network_id => @network_id,
        :network_uuid => @uuid,
        :network_type => self.network_type,
        :vif_uuid => service_map.vif.uuid,
        :active_datapath_id => service_map.vif.active_datapath_id,
        :service_mac => Trema::Mac.new(service_map.vif.mac_addr),
        :service_ipv4 => IPAddr.new(service_map.vif.ipv4_address, Socket::AF_INET)
      }

      info "network(#{@uuid}): creating service '#{service_map.display_name}'"

      service = case service_map.display_name
                when 'arp_lookup' then Vnet::Openflow::Services::ArpLookup.new(translated_map)
                when 'dhcp'       then Vnet::Openflow::Services::Dhcp.new(translated_map)
                when 'router'     then Vnet::Openflow::Services::Router.new(translated_map)
                else
                  error "network(#{@uuid}): failed to create service '#{service_map.uuid}'"
                  return
                end

      @service_cookies[service_map.uuid] = cookie

      if translated_map[:active_datapath_id] &&
          translated_map[:active_datapath_id] != @datapath_of_bridge[:datapath_id]
        return
      end

      pm = @datapath.packet_manager

      cookie = pm.insert(service,
                         nil,
                         service_map.id | (COOKIE_PREFIX_SERVICE << COOKIE_PREFIX_SHIFT))

      if cookie.nil?
        error "network(#{@uuid}): aborting creation of services '#{service_map.uuid}'"
        return
      end

      pm.dispatch(:arp)  { |key, handler| handler.insert_vif(service_map.vif.uuid, self, service_map.vif) }
      pm.dispatch(:icmp) { |key, handler| handler.insert_vif(service_map.vif.uuid, self, service_map.vif) }
    end

    def uninstall
      info "network(#{@uuid}): removing flows"

      pm = @datapath.packet_manager

      @datapath.del_cookie(@cookie)

      @service_cookies.each { |uuid,cookie|
        pm.remove(cookie)
        pm.dispatch(:arp)  { |key, handler| handler.remove_vif(service.vif_uuid) }
        pm.dispatch(:icmp) { |key, handler| handler.remove_vif(service.vif_uuid) }
      }
    end

  end

end
