# -*- coding: utf-8 -*-

module Vnet::Openflow::Tunnels

  class Mac2Mac < Base

    def mode
      :mac2mac
    end

    def log_type
      'tunnels/mac2mac'
    end

    def create_tunnel
      return if @tunnel_created == true

      info log_format("installed",
                      "src_ipv4_address:#{@src_ipv4_address.to_s} dst_ipv4_address:#{@dst_ipv4_address.to_s}")
    end

    def delete_tunnel
      debug log_format("removing flows")

      return if @tunnel_created == false

      @tunnel_created = false
    end

    #
    # Internal methods:
    #

    private

  end

end
