# -*- coding: utf-8 -*-

module Vnet::Openflow::Tunnels

  class Base < Vnet::ItemDpUuid
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_reader :dst_ipv4_address
    attr_reader :datapath_networks
    attr_reader :datapath_route_links

    attr_reader :dst_datapath_id
    attr_reader :dst_interface_id
    attr_reader :src_interface_id

    attr_reader :tunnel_port_number
    attr_reader :host_port_number

    def initialize(params)
      super

      map = params[:map]

      @dst_datapath_id = map.dst_datapath_id
      @dst_interface_id = map.dst_interface_id
      @src_interface_id = map.src_interface_id

      @tunnel_created = false

      @datapath_networks = []
      @datapath_route_links = []
    end
    
    def mode
      :base
    end

    def log_type
      'tunnels/base'
    end

    def cookie(tag = nil)
      value = @id | COOKIE_TYPE_TUNNEL
      tag.nil? ? value : (value | (tag << COOKIE_TAG_SHIFT))
    end

    def to_hash
      Vnet::Openflow::Tunnel.new(id: @id,
                                 uuid: @uuid,
                                 port_name: @display_name,

                                 dst_datapath_id: @dst_datapath_id,
                                 dst_interface_id: @dst_interface_id,
                                 src_interface_id: @src_interface_id,
                                 dst_network_id: @dst_network_id,
                                 src_network_id: @src_network_id,
                                 dst_ipv4_address: @dst_ipv4_address,
                                 src_ipv4_address: @src_ipv4_address,

                                 datapath_networks_size: @datapath_networks.size)
    end

    def unused?
      @datapath_networks.empty? && @datapath_route_links.empty?
    end

    def has_network_id?(network_id)
      @datapath_networks.any? { |dpn| dpn[:network_id] == network_id }
    end

    def detect_network_id?(network_id)
      @datapath_networks.find { |dpn| dpn[:network_id] == network_id }
    end

    def update_mode(mode)
      MW::Tunnel.batch.update_mode(@id, mode).commit
    end

    #
    # Specialization:
    #

    def install
      if @dst_network_id && @dst_ipv4_address &&
          @src_network_id && @src_ipv4_address
        #create_tunnel
      end
    end

    def uninstall
      delete_tunnel
    end

    def create_tunnel
    end

    def delete_tunnel
    end

    def actions_append_flood(network_id, tunnel_actions, mac2mac_actions)
    end

    #
    # Events:
    #
    
    def add_datapath_network(datapath_network)
      raise ArgumentError, "missing network_id parameter" unless datapath_network[:network_id]

      return if @datapath_networks.detect { |d| d[:id] == datapath_network[:id] }
      @datapath_networks << datapath_network
    end

    def remove_datapath_network(dpn_id)
      @datapath_networks.delete_if { |d| d[:id] == dpn_id }
    end

    def add_datapath_route_link(datapath_route_link)
      raise ArgumentError, "missing route_link_id parameter" unless datapath_route_link[:route_link_id]

      return if @datapath_route_links.detect { |d| d[:id] == datapath_route_link[:id] }
      @datapath_route_links << datapath_route_link
    end

    def remove_datapath_route_link(dprl_id)
      @datapath_route_links.delete_if { |d| d[:id] == dprl_id }
    end

    def set_dst_ipv4_address(network_id, ipv4_address)
      # Properly handle these case:
      return if @dst_network_id || @dst_ipv4_address
      return if network_id.nil? || ipv4_address.nil?

      @dst_network_id = network_id
      @dst_ipv4_address = ipv4_address

      # Return if not installed or tunnel already created, and add a
      # 'tunnel created' flag.
      create_tunnel if @src_network_id && @src_ipv4_address # && installed?
    end

    def set_src_ipv4_address(network_id, ipv4_address)
      # Properly handle these case:
      return if @src_network_id || @src_ipv4_address
      return if network_id.nil? || ipv4_address.nil?

      @src_network_id = network_id
      @src_ipv4_address = ipv4_address

      # Return if not installed or tunnel already created, and add a
      # 'tunnel created' flag.
      create_tunnel if @dst_network_id && @dst_ipv4_address # && installed?
    end

    def set_tunnel_port_number(new_port_number, updated_networks)
      return if new_port_number.nil?
      return if new_port_number == @tunnel_port_number

      @tunnel_port_number = new_port_number

      return if self.mode != :gre

      @datapath_networks.each { |dpn|
        updated_networks[dpn[:network_id]] = true
      }
    end

    def clear_tunnel_port_number(updated_networks)
      return if @tunnel_port_number.nil?
      @tunnel_port_number = nil

      return if self.mode != :gre

      @datapath_networks.each { |dpn|
        updated_networks[dpn[:network_id]] = true
      }
    end

    def set_host_port_number(new_port_number, updated_networks)
      return if new_port_number.nil?
      return if new_port_number == @host_port_number

      @host_port_number = new_port_number

      return if self.mode != :mac2mac

      @datapath_networks.each { |dpn|
        updated_networks[dpn[:network_id]] = true
      }
    end

  end

end
