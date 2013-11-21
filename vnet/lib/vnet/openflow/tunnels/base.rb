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

    attr_accessor :port_number

    def initialize(params)
      @dp_info = params[:dp_info]
      @manager = params[:manager]

      map = params[:map]

      @id = map.id
      @uuid = map.uuid
      @display_name = map.display_name

      @dst_id = map.dst_datapath_id

      if map.dst_datapath
        @dst_dpid = map.dst_datapath.dpid
        @dst_ipv4_address = IPAddr.new(map.dst_datapath.ipv4_address, Socket::AF_INET)
      end

      @datapath_networks = []
    end
    
    def to_hash
      Vnet::Openflow::Tunnel.new(id: @id,
                                 uuid: @uuid,
                                 port_name: @display_name,
                                 
                                 dst_id: @dst_id,
                                 dst_dpid: @dst_dpid,
                                 dst_ipv4_address: @dst_ipv4_address,
                                 
                                 datapath_networks_size: @datapath_networks.size,
                                 )
    end

    def install
      if @dst_ipv4_address.nil?
        error log_format("no valid destination datapath loaded for #{@uuid}",
                         "dst_datapath_id:#{@dst_datapath_id}")
        return
      end

      if !@dst_ipv4_address.ipv4?
        error log_format("no valid remote IPv4 address for #{@uuid}",
                         "ip_address:#{@dst_ipv4_address.to_s}")
        return
      end

      @dp_info.add_tunnel(@display_name, @dst_ipv4_address.to_s)

      info log_format("install #{@display_name}", "ip_address:#{@dst_ipv4_address.to_s}")
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
