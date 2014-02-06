# -*- coding: utf-8 -*-

module Vnet::Openflow::Tunnels

  class Gre < Base

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

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} tunnels/gre: #{message}" + (values ? " (#{values})" : '')
    end

  end

end
