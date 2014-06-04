# -*- coding: utf-8 -*-

module Vnet::Core::Interfaces

  # Remote interface types are any type of interface that is located
  # on other datapaths.

  class Remote < Base

    def initialize(params)
      super

      @remote_mode = @mode
      @mode = :remote
    end

    def log_type
      'interface/remote'
    end

    def add_ipv4_address(params)
      mac_info, ipv4_info = super

      if @remote_mode == :host
        @dp_info.tunnel_manager.async.update(event: :updated_interface,
                                             interface_event: :added_ipv4_address,
                                             interface_mode: :remote,
                                             interface_id: @id,
                                             network_id: ipv4_info[:network_id],
                                             ipv4_address: ipv4_info[:ipv4_address])
      end
    end

    def enable_router_egress
      return if @router_egress != false
      @router_egress = true
    end

    def disable_router_egress
      # Not supported atm.
    end

  end

end
