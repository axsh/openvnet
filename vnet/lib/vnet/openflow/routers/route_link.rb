# -*- coding: utf-8 -*-

require 'racket'

module Vnet::Openflow::Routers

  class RouteLink < Vnet::Openflow::PacketHandler

    def initialize(params)
      super(params[:datapath])
      @route_link_id = params[:route_link_id]
      @routes = {}
    end

    def install
      # debug "service::router.install: network:#{@network_uuid} vif_uuid:#{@vif_uuid.inspect} mac:#{@service_mac} ipv4:#{@service_ipv4}"
    end

    def insert_route(route_map)
      debug "service::router.insert_route: network:#{@network_uuid} route:#{route_map.inspect}"

      if @routes.has_key? route_map[:id]
        warn "service::router.insert_route: route already exists (#{route_map[:uuid]})"
        return nil
      end

      route = {
        :route_id => route_map[:id],
        :network_id => route_map[:vif][:network_id],
        :mac_address => route_map[:vif][:mac_addr],
        :ipv4_address => route_map[:ipv4_address],
        :ipv4_mask => route_map[:ipv4_mask]
      }

      cookie = route_map[:id] | (COOKIE_PREFIX_ROUTE << COOKIE_PREFIX_SHIFT)
      catch_route_md = md_create({ :network => route[:network_id],
                                   :local => nil
                                 })

      flow = Vnet::Openflow::Flow.create(TABLE_ROUTER_DST, 30,
                                         catch_route_md.merge({ :eth_type => 0x0800,
                                                                :eth_src => route[:mac_address],
                                                                :ipv4_dst => route[:ipv4_address],
                                                                :ipv4_dst_mask => route[:ipv4_mask],
                                                              }), {
                                           :output => OFPP_CONTROLLER
                                         }, {
                                           :cookie => cookie
                                         })

      @datapath.add_flow(flow)
      @routes[cookie] = route

      cookie
    end

    def packet_in(port, message)
      # debug "service::router.packet_in: #{message.inspect}"

      route = @routes[message.cookie]

      return unreachable_ip(message, "no route found", :no_route) if route.nil?

      ip_lease = MW::IpLease.batch.dataset.with_ipv4.where({ :ip_leases__network_id => route[:network_id],
                                                             :ip_addresses__ipv4_address => message.ipv4_dst.to_i
                                                           }).first.commit(:fill => :vif)

      return unreachable_ip(message, "no vif found", :no_vif) if ip_lease.nil? || ip_lease.vif.nil?
      return unreachable_ip(message, "no active vif found", :inactive_vif) if ip_lease.vif.datapath_id.nil?

      debug "service::router.packet_in: found ip lease (cookie:0x%x ipv4:#{message.ipv4_dst})" % message.cookie
      
      route_packets(message, ip_lease)

      # output...
    end

    private

    def match_packet(message)
      # Verify metadata is a network type.

      match = md_create({ :network => message.match.metadata & METADATA_VALUE_MASK,
                          :local => nil
                        })
      match.merge!({ :eth_type => 0x0800,
                     :eth_src => message.eth_src,
                     :ipv4_dst => message.ipv4_dst
                   })
    end

    # Create a flow that matches all packets to the same destination
    # ip address. The metadata datapath id table will figure out for
    # us if the output port should be a MAC2MAC or tunnel port.
    def route_packets(message, ip_lease)
      datapath_md = md_create(:datapath => ip_lease.vif.datapath_id)

      flow = Flow.create(TABLE_ROUTER_DST, 35,
                         match_packet(message), {
                           :eth_dst => Trema::Mac.new(ip_lease.vif.mac_addr),
                           :tunnel_id => ip_lease.network_id | TUNNEL_FLAG
                         },
                         datapath_md.merge({ :goto_table => TABLE_METADATA_DATAPATH_ID,
                                             :cookie => message.cookie,
                                             :idle_timeout => 60 * 60
                                           }))

      @datapath.add_flow(flow)
    end

    def suppress_packets(message, reason)
      # These should set us as listeners to events for the vif
      # becoming active or IP address being leased.
      case reason
      when :no_route
        hard_timeout = 30
      when :no_vif
        hard_timeout = 30
      when :inactive_vif
        hard_timeout = 10
      end

      flow = Flow.create(TABLE_ROUTER_DST, 35,
                         match_packet(message),
                         nil, {
                           :cookie => message.cookie,
                           :hard_timeout => hard_timeout
                         })

      @datapath.add_flow(flow)
    end

    def unreachable_ip(message, error_msg, suppress_reason)
      debug "service::router.packet_in: #{error_msg} (cookie:0x%x ipv4:#{message.ipv4_dst})" % message.cookie
      suppress_packets(message, suppress_reason)
      nil
    end

  end

end
