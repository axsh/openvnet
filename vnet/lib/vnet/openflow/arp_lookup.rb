# -*- coding: utf-8 -*-

require 'racket'

module Vnet::Openflow

  module ArpLookup
    include Vnet::Constants::Openflow

    def arp_lookup_initialize(params)
      @arp_lookup = {
        :interface_id => params[:interface_id],
        :lookup_cookie => params[:lookup_cookie],
        :reply_cookie => params[:reply_cookie],
        :requests => {}
      }
    end

    def arp_lookup_base_flows(flows)
      flows << flow_create(:catch_interface_simulated,
                           match: {
                             :eth_type => 0x0806,
                             :arp_op => 2,
                           },
                           interface_id: @arp_lookup[:interface_id],
                           cookie: @arp_lookup[:reply_cookie])
    end

    def arp_lookup_ipv4_flows(flows, mac_info, ipv4_info)
      flows << flow_create(:catch_arp_lookup,
                           match: {
                             :eth_src => mac_info[:mac_address],
                             :eth_type => 0x0800
                           },
                           network_id: ipv4_info[:network_id],
                           cookie: @arp_lookup[:lookup_cookie])
    end

    def arp_lookup_lookup_packet_in(message)
      port_number = message.match.in_port

      debug "arp_lookup_lookup_packet_in: port_number:#{port_number} ipv4_dst:#{message.ipv4_dst}"

      # Check if the address is in the same network, or if we need
      # to look up a gateway mac address.
      request_ipv4 = message.ipv4_dst

      # TODO: This should be done every time process_timeout is called...

      # TODO: Currently relies on metadata to identify the
      # network. For n-hop routing, figure out when the a gateway /
      # route should be looked up.
      mac_info, ipv4_info, network = find_ipv4_and_network(message, nil)
      return if network.nil?

      messages = @arp_lookup[:requests][request_ipv4] ||= []
      messages << {
        :message => message,
        :timestamp => Time.now
      }

      if messages.size == 1
        arp_lookup_process_timeout(interface_mac: mac_info[:mac_address],
                                   interface_ipv4: ipv4_info[:ipv4_address],
                                   request_ipv4: request_ipv4,
                                   attempts: 1)
      end

      messages.drop(5) if messages.size > 20
    end

    def arp_lookup_reply_packet_in(message)
      port_number = message.match.in_port

      debug "arp_lookup_reply_packet_in: port_number:#{port_number} arp_spa:#{message.arp_spa}"

      mac_info, ipv4_info = get_ipv4_address(any_md: message.match.metadata,
                                             ipv4_address: message.arp_tpa)
      return if mac_info.nil? || ipv4_info.nil?

      return if ipv4_info[:network_type] != :physical

      match_md = md_create(:network => ipv4_info[:network_id])
      reflection_md = md_create(:reflection => nil)

      cookie = ipv4_info[:network_id] | (COOKIE_PREFIX_NETWORK << COOKIE_PREFIX_SHIFT)

      flow = Flow.create(TABLE_ARP_LOOKUP, 25,
                         match_md.merge({ :eth_type => 0x0800,
                                          :ipv4_dst => message.arp_spa
                                        }), {
                           :eth_dst => message.arp_sha
                         },
                         reflection_md.merge!({ :cookie => cookie,
                                                :idle_timeout => 3600,
                                                :goto_table => TABLE_NETWORK_DST_CLASSIFIER
                                              }))

      @datapath.add_flow(flow)        

      arp_lookup_send_packets(@arp_lookup[:requests].delete(message.arp_spa))
    end

    def arp_lookup_process_timeout(params)
      messages = @arp_lookup[:requests][params[:request_ipv4]]

      if messages.nil? || Time.now - messages.last[:timestamp] > 5.0
        @arp_lookup[:requests].delete(params[:request_ipv4])
        return
      end

      # TODO: When we've received above a certain number of packets,
      # add a flow to drop packets before they get passed to the
      # controller.

      # Remove old packets...
      messages.select! { |message| Time.now - message[:timestamp] < 30.0 }

      @manager.after([params[:attempts], 10].min) {
        params[:attempts] = params[:attempts] + 1
        arp_lookup_process_timeout(params)
      }

      debug "arp_lookup: process timeout (ipv4_dst:#{params[:request_ipv4]} attempts:#{params[:attempts]})"

      packet_arp_out({ :out_port => OFPP_TABLE,
                       :in_port => OFPP_LOCAL,
                       :eth_src => params[:interface_mac],
                       :op_code => Racket::L3::ARP::ARPOP_REQUEST,
                       :sha => params[:interface_mac],
                       :spa => params[:interface_ipv4],
                       :tpa => params[:request_ipv4]
                     })
    end

    def arp_lookup_send_packets(messages)
      return if messages.nil?

      messages.each { |message|
        # Set the in_port to OFPP_CONTROLLER since the packets stored
        # have already been processed by TABLE_CLASSIFIER to
        # TABLE_ARP_LOOKUP, and as such no longer match the fields
        # required by the old in_port.
        #
        # The route link is identified by eth_dst, which was set in
        # TABLE_ROUTER_LINK prior to be sent to the controller.
        message[:message].match.in_port = OFPP_CONTROLLER

        @datapath.send_packet_out(message[:message], OFPP_TABLE)
      }
    end

  end

end
