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

      self.datapath.add_flow(flow)
      @routes[cookie] = route

      cookie
    end

    def packet_in(port, message)
      # debug "service::router.packet_in: #{message.inspect}"

      route = @routes[message.cookie]

      if route.nil?
        debug "service::router.packet_in: no route found (cookie:0x%x ipv4:#{message.ipv4_dst})" % message.cookie
        return
      end

      ip_lease = MW::IpLease.batch.dataset.with_ipv4.where({ :ip_leases__network_id => @network_id,
                                                             :ip_addresses__ipv4_address => message.ipv4_dst.to_i
                                                           }).first.commit(:fill => :vif)

      if ip_lease.nil?
        debug "service::router.packet_in: no vif found (cookie:0x%x ipv4:#{message.ipv4_dst})" % message.cookie
        return
      end

      debug "service::router.packet_in: found ip lease #{ip_lease.inspect}"

      cookie = message.cookie
      catch_md = md_create({ :virtual_network => @network_id,
                             :local => nil
                           })

      # Replace with a table for routing to remote mac2mac and
      # tunnels based on destination datapath id, etc.
      eth_port = @datapath.switch.eth_ports.first

      return if eth_port.nil?

      # mac2mac...

      flow = Vnet::Openflow::Flow.create(TABLE_ROUTER_DST, 35,
                                         catch_md.merge({ :eth_type => 0x0800,
                                                          :eth_src => @service_mac,
                                                          :ipv4_dst => message.ipv4_dst
                                                        }), {
                                           :output => eth_port.port_number
                                         }, {
                                           :cookie => cookie,
                                           :idle_timeout => 60 * 60
                                         })

      self.datapath.add_flow(flow)

      # output...
    end

  end

end
