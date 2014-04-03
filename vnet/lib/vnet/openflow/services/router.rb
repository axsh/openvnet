# -*- coding: utf-8 -*-

require 'racket'

module Vnet::Openflow::Services

  class Router < Base

    def log_type
      'service/router'
    end

    def install
      debug log_format('install', "interface_id:#{@interface_id}")
    end

    #
    # Internal methods:
    #

    private

  end

end
