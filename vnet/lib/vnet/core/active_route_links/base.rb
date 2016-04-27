# -*- coding: utf-8 -*-

module Vnet::Core::ActiveRouteLinks

  class Base < Vnet::ItemDpBase
    include Vnet::Openflow::FlowHelpers

    attr_reader :route_link_id
    attr_reader :datapath_id

    def initialize(params)
      super

      map = params[:map]

      @route_link_id = map.route_link_id
      @datapath_id = map.datapath_id
    end

    def mode
      :base
    end

    def log_type
      'active_route_link/base'
    end

    def pretty_id
      "#{mode}/#{id}"
    end

    def pretty_properties
      "route_link_id:#{@route_link_id} datapath_id:#{@datapath_id}"
    end

    def cookie
      @id | COOKIE_TYPE_ACTIVE_ROUTE_LINK
    end

    def to_hash
      Vnet::Core::ActiveRoute_Link.new(id: @id,
                                    mode: self.mode,

                                    route_link_id: @route_link_id,
                                    datapath_id: @datapath_id)
    end

  end

end
