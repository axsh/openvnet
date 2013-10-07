# -*- coding: utf-8 -*-

require 'racket'

module Vnet::Openflow::Routers

  class RouteLink < Vnet::Openflow::PacketHandler

    def initialize(params)
      super(params[:datapath])

      @routes = {}
      @route_link_id = params[:route_link_id]
      @route_link_uuid = params[:route_link_uuid]
      @mac_address = params[:mac_address]

      @dpid = @datapath.dpid
      @dpid_s = "0x%016x" % @datapath.dpid
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
        :network_type => route_info[:interface][:network_type],

        :require_interface => route_info[:interface][:require_interface],
        :active_datapath_id => route_info[:interface][:active_datapath_id],

        :mac_address => route_info[:interface][:mac_addr],
        :ipv4_address => route_info[:ipv4_address],
        :ipv4_prefix => route_info[:ipv4_prefix],

        :ingress => route_info[:ingress],
        :egress => route_info[:egress],
      }

      cookie = route[:route_id] | (COOKIE_PREFIX_ROUTE << COOKIE_PREFIX_SHIFT)

      @routes[cookie] = route

      create_destination_flow(route)
      cookie
    end

    def packet_in(message)
      ipv4_dst = message.ipv4_dst
      ipv4_src = message.ipv4_src
      port_number = message.match.in_port

      route = @routes[message.cookie]

      debug log_format('packet_in',
                       "port_number:#{port_number} ipv4_src:#{ipv4_src.to_s} ipv4_dst:#{ipv4_dst.to_s}")

      return unreachable_ip(message, "no route found", :no_route) if route.nil?

      if route[:require_interface] == true
        filter_args = {
          :ip_leases__network_id => route[:network_id],
          :ip_addresses__ipv4_address => ipv4_dst.to_i
        }
        ip_lease = MW::IpLease.batch.dataset.where(filter_args).first.commit(:fill => [:interface, :ipv4_address)

        if ip_lease.nil? || ip_lease.interface.nil?
          return unreachable_ip(message, "no vif found", :no_vif)
        end

        if ip_lease.interface.active_datapath_id.nil?
          return unreachable_ip(message, "no active datapath for vif found", :inactive_vif)
        end

        debug log_format('packet_in, found ip lease', "cookie:0x%x ipv4:#{ipv4_dst}" % message.cookie)

        route_packets(message, ip_lease)
        send_packet(message)

      else
        debug log_format('packet_in, no destination interface needed for route', "#{route[:uuid]}")
      end
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values)
      "#{@dpid_s} router::router_link: #{message} (route_link:#{@route_link_uuid}/#{@route_link_id}#{values ? ' ' : ''}#{values})"
    end

    def create_destination_flow(route)
      cookie = route[:route_id] | (COOKIE_PREFIX_ROUTE << COOKIE_PREFIX_SHIFT)

      if route[:require_vif] == true
        catch_route_md = md_create(network: route[:network_id],
                                   not_no_controller: nil)
        actions = { :output => OFPP_CONTROLLER }
        instructions = { :cookie => cookie }
      else
        catch_route_md = md_create(network: route[:network_id])
        actions = nil
        instructions = {
          :goto_table => TABLE_ARP_LOOKUP,
          :cookie => cookie
        }
      end

      if is_ipv4_broadcast(route[:ipv4_address], route[:ipv4_prefix])
        priority = 30
      else
        priority = 31
      end

      subnet_dst = match_ipv4_subnet_dst(route[:ipv4_address], route[:ipv4_prefix])

      flow = Flow.create(TABLE_ROUTER_DST, priority,
                         catch_route_md.merge(subnet_dst).merge(:eth_src => route[:mac_address]),
                         actions,
                         instructions)

      @datapath.add_flow(flow)
    end

    def match_packet(message)
      # Verify metadata is a network type.

      match = md_create(:network => message.match.metadata & METADATA_VALUE_MASK)
      match.merge!({ :eth_type => 0x0800,
                     :eth_src => message.eth_src,
                     :ipv4_dst => message.ipv4_dst
                   })
    end

    # Create a flow that matches all packets to the same destination
    # ip address. The output datapath route link table will figure out
    # for us if the output port should be a MAC2MAC or tunnel port.
    def route_packets(message, ip_lease)
      actions_md = md_create({ :datapath => ip_lease.interface.active_datapath_id,
                               :reflection => nil
                             })

      flow = Flow.create(TABLE_ROUTER_DST, 35,
                         match_packet(message), {
                           :eth_dst => @mac_address
                         },
                         actions_md.merge({ :goto_table => TABLE_OUTPUT_DP_ROUTE_LINK,
                                            :cookie => message.cookie,
                                            :idle_timeout => 60 * 60
                                          }))

      @datapath.add_flow(flow)
    end

    def suppress_packets(message, reason)
      # These should set us as listeners to events for the interface
      # becoming active or IP address being leased.
      case reason
      when :no_route     then hard_timeout = 30
      when :no_interface       then hard_timeout = 30
      when :inactive_interface then hard_timeout = 10
      end

      flow = Flow.create(TABLE_ROUTER_DST, 35,
                         match_packet(message),
                         nil, {
                           :cookie => message.cookie,
                           :hard_timeout => hard_timeout
                         })

      @datapath.add_flow(flow)
    end

    def send_packet(message)
      # We're modifying the in_port field, so duplicate the message to
      # avoid race conditions with the flow add message.
      message = message.dup

      # Set the in_port to OFPP_CONTROLLER since the packets stored
      # have already been processed by TABLE_CLASSIFIER to
      # TABLE_ROUTER_DST, and as such no longer match the fields
      # required by the old in_port.
      #
      # The route link is identified by eth_dst, which was set in
      # TABLE_ROUTER_EGRESS prior to be sent to the controller.
      message.match.in_port = OFPP_CONTROLLER

      @datapath.send_packet_out(message, OFPP_TABLE)
    end

    def unreachable_ip(message, error_msg, suppress_reason)
      debug log_format("packet_in, error '#{error_msg}'", "cookie:0x%x ipv4:#{message.ipv4_dst}" % message.cookie)
      suppress_packets(message, suppress_reason)
      nil
    end

  end

end
