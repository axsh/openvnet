# -*- coding: utf-8 -*-

require 'racket'

module Vnet::Openflow::Services

  class Router < Base

    def install
      @dp_info.interface_manager.async.update_item(event: :enable_router_ingress,
                                                   id: @interface_id)
      @dp_info.interface_manager.async.update_item(event: :enable_router_egress,
                                                   id: @interface_id)

      debug log_format('install', "interface_id:#{@interface_id}")
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} services/router: #{message}" + (values ? " (#{values})" : '')
    end

  end

end
