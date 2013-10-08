# -*- coding: utf-8 -*-

module Vnet::Openflow::Tunnels

  class Base
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_reader :id
    attr_reader :uuid
    attr_reader :display_name

    attr_reader :dst_id
    attr_reader :dst_dpid
    attr_reader :dst_ipv4_address

    attr_reader :datapath_networks

    def initialize(params)
      @dp_info = params[:dp_info]
      @manager = params[:manager]

      map = params[:map]

      @id = map.id
      @uuid = map.uuid
      @display_name = map.display_name

      @dst_id = params[:dst_dp_map].id
      @dst_dpid = params[:dst_dp_map].dpid
      @dst_ipv4_address = IPAddr.new(params[:dst_dp_map].dst_ipv4_address, Socket::AF_INET)

      @datapath_networks = []
    end
    
    # def cookie(tag = nil)
    #   value = @id | (COOKIE_PREFIX_TUNNEL << COOKIE_PREFIX_SHIFT)
    #   tag.nil? ? value : (value | (tag << COOKIE_TAG_SHIFT))
    # end

    def to_hash
      { :id => @id,
        :uuid => @uuid,
      }
    end

    def install
      info log_format("install #{@display_name}")

      @dp_info.add_tunnel(@display_name, @dst_ipv4_address.to_s)
    end

    def uninstall
      debug log_format("removing flows")

      @dp_info.delete_tunnel(@display_name)

      # cookie_value = self.cookie
      # cookie_mask = COOKIE_PREFIX_MASK | COOKIE_ID_MASK

      # @dp_info.del_cookie(cookie_value, cookie_mask)
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} tunnels/base: #{message}" + (values ? " (#{values})" : '')
    end

  end

end
