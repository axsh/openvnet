# -*- coding: utf-8 -*-

module Vnet::Core::Tunnels

  class Gre < Base

    def mode
      :gre
    end

    def log_type
      'tunnels/gre'
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

      if !is_address_ipv4?(@dst_ipv4_address)
        error log_format_h("no valid remote IPv4 address for #{@uuid}", dst_ipv4_address: @dst_ipv4_address.inspect)
        return
      end

      if !is_address_ipv4?(@src_ipv4_address)
        error log_format_h("no valid local IPv4 address for #{@uuid}", src_ipv4_address: @src_ipv4_address.inspect)
        return
      end

      @tunnel_created = true

      @dp_info.add_tunnel(@uuid,
                          remote_ip: @dst_ipv4_address.to_s,
                          local_ip: @src_ipv4_address.to_s)

      flows = []

      [true, false].each { |reflection|
        flows << flow_create(table: TABLE_OUTPUT_TUNNEL_SIF_DIF,
                             goto_table: TABLE_OUT_PORT_EGRESS_TUN_NIL,
                             priority: 1,

                             match_remote: reflection,
                             match_first: @src_interface_id,
                             match_second: @dst_interface_id,

                             write_first: @id,
                             write_second: 0
                            )
      }

      @dp_info.add_flows(flows)

      info log_format("installed",
                      "src_ipv4_address:#{@src_ipv4_address} dst_ipv4_address:#{@dst_ipv4_address}")
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

    def actions_append_flood_network(network_id, tunnel_actions, mac2mac_actions)
      return if @tunnel_port_number.nil? || !has_network_id?(network_id)

      tunnel_actions << { output: @tunnel_port_number }
    end

    def actions_append_flood_segment(segment_id, tunnel_actions, mac2mac_actions)
      return if @tunnel_port_number.nil? || !has_segment_id?(segment_id)

      tunnel_actions << { output: @tunnel_port_number }
    end

    #
    # Internal methods:
    #

    private

  end

end
