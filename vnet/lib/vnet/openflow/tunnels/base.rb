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
      end

      @dst_interface = map.dst_interface
      @src_interface = map.src_interface

      @src_interface_id = map.src_interface_id
      @dst_interface_id = map.dst_interface_id

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

                                 dst_id: @dst_id,
                                 dst_dpid: @dst_dpid,
                                 dst_ipv4_address: @dst_ipv4_address,
                                 src_ipv4_address: @src_ipv4_address,

                                 datapath_networks_size: @datapath_networks.size,
                                 )
    end

    def install
      if @dst_interface.nil?
        error log_format("no valid destination interface loaded for #{@uuid}")
        return
      end

      if @src_interface.nil?
        error log_format("no valid source interface loaded for #{@uuid}")
        return
      end

      @dst_ipv4_address = IPAddr.new(@dst_interface.ipv4_address, Socket::AF_INET)
      @src_ipv4_address = IPAddr.new(@src_interface.ipv4_address, Socket::AF_INET)

      if !@dst_ipv4_address.ipv4?
        error log_format("no valid remote IPv4 address for #{@uuid}",
                         "ip_address:#{@dst_ipv4_address.to_s}")
        return
      end

      if !@src_ipv4_address.ipv4?
        error log_format("no valid local IPv4 address for #{@uuid}",
                         "ip_address:#{@src_ipv4_address.to_s}")
        return
      end

      if !(@src_interface_id && @src_interface_id > 0) ||
          !(@dst_interface_id && @dst_interface_id > 0)
        error log_format("no valid src/dst interface id's found for #{@uuid}")
        return
      end

      @dp_info.add_tunnel(@uuid,
                          remote_ip: @dst_ipv4_address.to_s,
                          local_ip: @src_ipv4_address.to_s)

      flows = []

      [true, false].each { |reflection|
        flows << flow_create(:default,
                             table: TABLE_OUTPUT_DP_OVER_TUNNEL,
                             goto_table: TABLE_OUT_PORT_TUNNEL,
                             priority: 1,

                             match_value_pair_flag: reflection,
                             match_value_pair_first: @src_interface_id,
                             match_value_pair_second: @dst_interface_id,

                             clear_all: true,
                             write_tunnel: @id,
                             write_reflection: reflection)
      }

      @dp_info.add_flows(flows)

      info log_format("install #{@display_name}", "ip_address:#{@dst_ipv4_address.to_s}")
    end

    def uninstall
      debug log_format("removing flows")

      @dp_info.delete_tunnel(@uuid)

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
