# -*- coding: utf-8 -*-

module Vnet::Openflow::Tunnels

  class Base < Vnet::Openflow::ItemBase
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_reader :uuid
    attr_reader :dst_ipv4_address
    attr_reader :datapath_networks

    attr_reader :dst_datapath_id
    attr_reader :dst_interface_id
    attr_reader :src_interface_id

    attr_accessor :port_number

    def initialize(params)
      super

      map = params[:map]

      @id = map.id
      @uuid = map.uuid

      @dst_datapath_id = map.dst_datapath_id
      @dst_interface_id = map.dst_interface_id
      @src_interface_id = map.src_interface_id

      @tunnel_created = false

      @datapath_networks = []
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
      @datapath_networks.empty?
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

    #
    # Events:
    #
    
    def add_datapath_network(datapath_network)
      return if @datapath_networks.detect { |d| d[:id] == datapath_network[:id] }
      @datapath_networks << datapath_network
    end

    def remove_datapath_network(dpn_id)
      @datapath_networks.find { |d| d[:id] == dpn_id }.tap do |datapath_network|
        @datapath_networks.delete(datapath_network) if datapath_network
      end
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

  end

end
