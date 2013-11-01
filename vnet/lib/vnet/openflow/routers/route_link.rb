# -*- coding: utf-8 -*-

require 'racket'

module Vnet::Openflow::Routers

  class RouteLink < Vnet::Openflow::PacketHandler

    def initialize(params)
      super(params[:dp_info])

      @dp_info = params[:dp_info]

      @routes = {}
      @route_link_id = params[:route_link_id]
      @route_link_uuid = params[:route_link_uuid]
      @mac_address = params[:mac_address]

      @dpid = @dp_info.dpid
      @dpid_s = @dp_info.dpid_s
    end

    def install
      debug log_format('install', "mac:#{@mac_address}")
    end

    def insert_route(route_info)
      ipv4_s = "#{route_info[:ipv4_address].to_s}/#{route_info[:ipv4_prefix]}"

      debug log_format('insert route', "route:#{route_info[:uuid]}/#{route_info[:id]} ipv4:#{ipv4_s}")

      if @routes.has_key? route_info[:id]
        warn log_format('route already exists', "#{route_info[:uuid]}")
        return nil
      end

      route = {
        :route_id => route_info[:id],
        :route_uuid => route_info[:uuid],
        :network_id => route_info[:interface][:network_id],

        :require_interface => route_info[:interface][:require_interface],
        :active_datapath_id => route_info[:interface][:active_datapath_id],

        :mac_address => route_info[:interface][:mac_address],
        :ipv4_address => route_info[:ipv4_address],
        :ipv4_prefix => route_info[:ipv4_prefix],

        :ingress => route_info[:ingress],
        :egress => route_info[:egress],

        :route_link => self
      }

      cookie = route[:route_id] | COOKIE_TYPE_ROUTE

      @routes[cookie] = route

      cookie
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values)
      "#{@dpid_s} router::router_link: #{message} (route_link:#{@route_link_uuid}/#{@route_link_id}#{values ? ' ' : ''}#{values})"
    end

  end

end
