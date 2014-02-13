# -*- coding: utf-8 -*-

module Vnet::Openflow::Tunnels

  class Gre < Base

    LOG_TYPE = 'tunnels/gre'

    def mode
      :gre
    end

    def create_tunnel
      return if @tunnel_created == true

      if @dst_interface_id.nil?
        error log_format("no valid destination interface id for #{@uuid}")
        return
      end

      if @src_interface_id.nil?
        error log_format("no valid source interface id for #{@uuid}")
        return
      end

      if @dst_ipv4_address.nil? || !@dst_ipv4_address.ipv4?
        error log_format("no valid remote IPv4 address for #{@uuid}",
                         "ipv4_address:#{@dst_ipv4_address.to_s}")
        return
      end

      if @src_ipv4_address.nil? || !@src_ipv4_address.ipv4?
        error log_format("no valid local IPv4 address for #{@uuid}",
                         "ipv4_address:#{@src_ipv4_address.to_s}")
        return
      end

      @tunnel_created = true

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

      info log_format("installed",
                      "src_ipv4_address:#{@src_ipv4_address.to_s} dst_ipv4_address:#{@dst_ipv4_address.to_s}")
    end

    def delete_tunnel
      debug log_format("removing flows")

      return if @tunnel_created == false

      @dp_info.delete_tunnel(@uuid)

      @tunnel_created = false

      # cookie_value = self.cookie
      # cookie_mask = COOKIE_PREFIX_MASK | COOKIE_ID_MASK

      # @dp_info.del_cookie(cookie_value, cookie_mask)
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
