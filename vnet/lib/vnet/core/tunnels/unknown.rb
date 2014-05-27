# -*- coding: utf-8 -*-

module Vnet::Core::Tunnels

  class Unknown < Base

    def mode
      :unknown
    end

    def log_type
      'tunnels/unknown'
    end

    def create_tunnel
      return if @tunnel_created == true

    end

    #
    # Internal methods:
    #

    private

  end

end
