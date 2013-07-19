# -*- coding: utf-8 -*-

require 'racket'

module Vnet::Openflow::Services

  class Router < Base
    attr_reader :network_id
    attr_reader :vif_uuid
    attr_reader :service_mac
    attr_reader :service_ipv4

    def initialize(params)
      super
      @network_id = params[:network_id]
      @network_uuid = params[:network_uuid]
      @vif_uuid = params[:vif_uuid]
      @service_mac = params[:service_mac]
      @service_ipv4 = params[:service_ipv4]

      @routes = {}
    end

    def install
      debug "service::router.install: network:#{@network_uuid} vif_uuid:#{@vif_uuid.inspect} mac:#{@service_mac} ipv4:#{@service_ipv4}"
    end

    def insert_route(route_map)
      debug "service::router.insert_route: network:#{@network_uuid} route:#{route_map.inspect}"

      if @routes.has_key? route_map[:id]
        warn "service::router.insert_route: route already exists (#{route_map[:uuid]})"
        return nil
      end

      route = {
        :route_id => route_map[:id],
        :ipv4_address => route_map[:ipv4_address],
        :ipv4_mask => route_map[:ipv4_mask]
      }

      cookie = route_map[:id] | (COOKIE_PREFIX_ROUTE << COOKIE_PREFIX_SHIFT)
      catch_route_md = md_create({ :virtual_network => @network_id,
                                   :local => nil
                                 })

      flow = Vnet::Openflow::Flow.create(TABLE_ROUTER_DST, 30,
                                         catch_route_md.merge({ :eth_type => 0x0800,
                                                                :eth_src => @service_mac,
                                                                :ipv4_dst => route[:ipv4_address],
                                                                :ipv4_dst_mask => route[:ipv4_mask],
                                                              }), {
                                           :output => OFPP_CONTROLLER
                                         }, {
                                           :cookie => cookie
                                         })

      @routes[cookie] = route
      self.datapath.add_flow(flow)

      cookie
    end

    def packet_in(port, message)
      debug "service::router.packet_in: called."

      debug "service::router.packet_in: #{message.inspect}"
    end

  end

end
