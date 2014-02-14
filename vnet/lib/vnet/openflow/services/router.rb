# -*- coding: utf-8 -*-

require 'racket'

module Vnet::Openflow::Services

  class Router < Base

    def install
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
