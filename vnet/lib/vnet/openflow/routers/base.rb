# -*- coding: utf-8 -*-

module Vnet::Openflow::Routers

  class Base < Vnet::ItemDpUuid
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_reader :mac_address

    def initialize(params)
      super

      map = params[:map]
      @mac_address = Trema::Mac.new(map.mac_address)

      @routes = {}
    end

    def log_type
      'router/base'
    end

    def cookie
      @id | COOKIE_TYPE_ROUTE_LINK
    end

    def to_hash
      Vnet::Openflow::Router.new(id: @id,
                                 uuid: @uuid,
                                 #mode: @mode,

                                 mac_address: @mac_address)
    end

    #
    # Events: 
    #

    def add_active_route(route_id)
      return if @routes.has_key? route_id

      @routes[route_id] = {
      }

      debug log_format("adding active route #{route_id}")
    end

    #
    # Internal methods:
    #

    private

  end

end
