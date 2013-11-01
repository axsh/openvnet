# -*- coding: utf-8 -*-

require 'racket'

module Vnet::Openflow::Routers

  class RouteLink

    attr_reader :id
    attr_reader :uuid
    attr_reader :mac_address

    attr_reader :routes

    def initialize(params)
      @dp_info = params[:dp_info]

      map = params[:map]

      @id = map.id
      @uuid = map.uuid
      @mac_address = Trema::Mac.new(map.mac_address)

      @routes = {}
    end

    def install
      debug log_format('install', "mac:#{@mac_address}")
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values)
      "#{@dp_info.dpid_s} router::router_link: #{message} (route_link:#{@uuid}/#{@id}#{values ? ' ' : ''}#{values})"
    end

  end

end
