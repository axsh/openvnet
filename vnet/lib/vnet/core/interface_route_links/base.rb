# -*- coding: utf-8 -*-

module Vnet::Core::InterfaceRouteLinks

  class Base < Vnet::ItemDpId
    attr_reader :interface_id
    attr_reader :route_link_id

    attr_accessor :static

    def initialize(params)
      super

      map = params[:map]

      @interface_id = get_param_id(map, :interface_id)
      @route_link_id = get_param_id(map, :route_link_id)
      @static = get_param_bool(map, :static)
    end

    def mode
      :base
    end

    def log_type
      'interface_route_link/base'
    end

    def pretty_id
      "#{mode}/#{id}"
    end

    def pretty_properties
      "interface_id:#{@interface_id} route_link_id:#{@route_link_id}" + (@static ? ' static' : '')
    end

    def install
      @dp_info.route_link_manager.insert_interface_route_link(@interface_id, @route_link_id)
    end

    def uninstall
      @dp_info.route_link_manager.remove_interface_route_link(@interface_id, @route_link_id)
    end

    def to_hash
      Vnet::Core::InterfaceRouteLink.new(
        id: @id,
        interface_id: @interface_id,
        route_link_id: @route_link_id,
        static: @static
      )
    end

  end

end
