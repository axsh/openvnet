# -*- coding: utf-8 -*-

module Vnet::Core::Tunnels

  class Mac2Mac < Base

    def mode
      :mac2mac
    end

    def log_type
      'tunnels/mac2mac'
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

      @tunnel_created = true

      # TODO: MAC2MAC does not need the src/dst ipv4 addresses.

      flows = []

      [true, false].each { |reflection|
        flows << flow_create(table: TABLE_OUTPUT_DP_OVER_MAC2MAC,
                             goto_table: TABLE_OUT_PORT_INTERFACE_EGRESS,
                             priority: 2,

                             match_value_pair_flag: reflection,
                             match_value_pair_first: @src_interface_id,
                             match_value_pair_second: @dst_interface_id,

                             clear_all: true,
                             write_interface: @src_interface_id,
                             write_reflection: reflection)
      }

      @dp_info.add_flows(flows)

      info log_format("installed",
                      "src_ipv4_address:#{@src_ipv4_address} dst_ipv4_address:#{@dst_ipv4_address}")
    end

    def delete_tunnel
      debug log_format("removing flows")

      return if @tunnel_created == false

      @tunnel_created = false

      # cookie_value = self.cookie
      # cookie_mask = COOKIE_PREFIX_MASK | COOKIE_ID_MASK

      # @dp_info.del_cookie(cookie_value, cookie_mask)
    end

    def actions_append_flood_network(network_id, tunnel_actions, mac2mac_actions)
      return if @host_port_number.nil?

      dpn = detect_network_id?(network_id) || return

      mac2mac_actions << {
        :eth_dst => dpn[:mac_address],
        :output => @host_port_number
      }
    end

    def actions_append_flood_segment(segment_id, tunnel_actions, mac2mac_actions)
      return if @host_port_number.nil?

      dpn = detect_segment_id?(segment_id) || return

      mac2mac_actions << {
        :eth_dst => dpn[:mac_address],
        :output => @host_port_number
      }
    end

    #
    # Internal methods:
    #

    private

  end

end
