# -*- coding: utf-8 -*-

module Vnet::Openflow::Tunnels

  class Base < Vnet::Openflow::ItemBase
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_reader :uuid
    attr_reader :mode
    attr_reader :dst_ipv4_address
    attr_reader :datapath_networks

    attr_reader :dst_datapath_id
    attr_reader :dst_interface_id
    attr_reader :src_interface_id

    attr_accessor :port_number

    LOG_TYPE = 'tunnels/base'

    def initialize(params)
      super

      map = params[:map]

      @id = map.id
      @uuid = map.uuid
      @mode = map.mode

      @dst_datapath_id = map.dst_datapath_id

      @dst_interface = map.dst_interface
      @src_interface = map.src_interface

      @dst_interface_id = map.dst_interface_id
      @src_interface_id = map.src_interface_id

      @datapath_networks = []
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
                                 dst_ipv4_address: @dst_ipv4_address,
                                 src_ipv4_address: @src_ipv4_address,

                                 datapath_networks_size: @datapath_networks.size)
    end

    def install
    end

    def uninstall
      debug log_format("removing flows")

      @dp_info.delete_tunnel(@uuid)

      # cookie_value = self.cookie
      # cookie_mask = COOKIE_PREFIX_MASK | COOKIE_ID_MASK

      # @dp_info.del_cookie(cookie_value, cookie_mask)
    end

    def add_datapath_network(datapath_network)
      return if @datapath_networks.detect { |d| d[:id] == datapath_network[:id] }
      @datapath_networks << datapath_network
    end

    def remove_datapath_network(dpn_id)
      @datapath_networks.find { |d| d[:id] == dpn_id }.tap do |datapath_network|
        @datapath_networks.delete(datapath_network) if datapath_network
      end
    end

    def unused?
      @datapath_networks.empty?
    end

  end

end
