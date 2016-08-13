# -*- coding: utf-8 -*-

require 'racket'

module Vnet::Openflow

  module ArpLookup
    include Vnet::Constants::Openflow

    def arp_lookup_initialize(params)
      @arp_lookup = {
        interface_id: params[:interface_id],
        lookup_cookie: params[:lookup_cookie],
        reply_cookie: params[:reply_cookie],
        requests: {}
      }
    end

    def arp_lookup_base_flows(flows)
      flows << flow_create(table: TABLE_OUT_PORT_INTERFACE_INGRESS,
                           priority: 30,
                           match: {
                             :eth_type => 0x0806,
                             :arp_op => 2,
                           },
                           match_interface: @arp_lookup[:interface_id],
                           actions: {
                             :output => Controller::OFPP_CONTROLLER
                           },
                           cookie: @arp_lookup[:reply_cookie])
    end

    def arp_lookup_ipv4_flows(flows, mac_info, ipv4_info)
      ipv4_info_mask = ipv4_info[:network_prefix]
      mac_address = mac_info[:mac_address]

      [[20, {
          :eth_src => mac_address,
          :eth_type => 0x0800
        }],
       [30, {
          :eth_src => mac_address,
          :eth_type => 0x0800,
          :ipv4_dst => ipv4_info[:ipv4_address].mask(ipv4_info_mask),
          :ipv4_dst_mask => IPV4_BROADCAST.mask(ipv4_info_mask)
        }]
      ].each { |priority, match|
        flows << flow_create(table: TABLE_ARP_LOOKUP,
                             priority: priority,
                             match: match,
                             match_network: ipv4_info[:network_id],
                             match_not_no_controller: true,
                             actions: {
                               :output => Controller::OFPP_CONTROLLER
                             },
                             cookie: @arp_lookup[:lookup_cookie])
      }
    end

    def arp_lookup_lookup_packet_in(message)
      port_number = message.match.in_port

      debug log_format('arp_lookup_lookup_packet_in',
                       "port_number:#{port_number} ipv4_dst:#{message.ipv4_dst}")

      # Check if the address is in the same network, or if we need
      # to look up a gateway mac address.
      request_ipv4 = message.ipv4_dst

      # TODO: This should be done every time process_timeout is called...

      # TODO: Currently relies on metadata to identify the
      # network. For n-hop routing, figure out when the a gateway /
      # route should be looked up.
      mac_info, ipv4_info, network = find_ipv4_and_network(message, nil)
      return if network.nil?

      network_address = network[:ipv4_network].dup.mask(network[:ipv4_prefix])

      if network_address.include?(request_ipv4)
        destination_ipv4 = nil
        destination_prefix = nil
      else
        request_ipv4 = arp_lookup_default_gw(network, network_address)
        destination_ipv4 = IPV4_BROADCAST
        destination_prefix = 0
      end

      messages = @arp_lookup[:requests][request_ipv4] ||= []
      messages << {
        :message => message,
        :timestamp => Time.now,
        :destination_ipv4 => destination_ipv4,
        :destination_prefix => destination_prefix
      }

      if messages.size == 1
        # Remove virtual network mode's use of db lookup until arp
        # lookup has been refactored, as the db lookups as-is won't
        # work with the active interface refactoring.

        case ipv4_info[:network_type]
        when :physical
          arp_lookup_process_timeout(interface_mac: mac_info[:mac_address],
                                     interface_ipv4: ipv4_info[:ipv4_address],
                                     interface_network_id: ipv4_info[:network_id],
                                     request_ipv4: request_ipv4,
                                     attempts: 1)
        when :virtual
          arp_lookup_datapath_lookup(interface_mac: mac_info[:mac_address],
                                     interface_ipv4: ipv4_info[:ipv4_address],
                                     interface_network_id: ipv4_info[:network_id],
                                     request_ipv4: request_ipv4,
                                     attempts: 1)
          # arp_lookup_process_timeout(interface_mac: mac_info[:mac_address],
          #                            interface_ipv4: ipv4_info[:ipv4_address],
          #                            interface_network_id: ipv4_info[:network_id],
          #                            request_ipv4: request_ipv4,
          #                            attempts: 1)
        end
      end

      messages.drop(5) if messages.size > 20
    end

    def arp_lookup_default_gw(network, network_address)
      network_conf = Vnet::Configurations::Vna.conf.network

      if network_conf.uuid && network_conf.uuid == network.uuid
        default_gw = network_conf.gateway && network_conf.gateway.address

        debug log_format("arp lookup using gateway '#{default_gw}'")

        return IPAddr.new(default_gw) if default_gw
      end

      network_address.mask(32) | IPAddr.new('0.0.0.1')
    end

    def arp_lookup_reply_packet_in(message)
      port_number = message.match.in_port

      debug log_format('arp_lookup_reply_packet_in',
                       "port_number:#{port_number} arp_spa:#{message.arp_spa}")

      mac_info, ipv4_info = get_ipv4_address(any_md: message.match.metadata,
                                             ipv4_address: message.arp_tpa)
      return if mac_info.nil? || ipv4_info.nil?

      match_md = md_create(:network => ipv4_info[:network_id])
      reflection_md = md_create(:reflection => nil)

      cookie = ipv4_info[:network_id] | COOKIE_TYPE_NETWORK

      flow = Flow.create(TABLE_ARP_LOOKUP, 35,
        match_md.merge({ :eth_type => 0x0800,
            :ipv4_dst => message.arp_spa
          }), {
          :eth_dst => message.arp_sha
        },
        reflection_md.merge!({ :cookie => cookie,
            :idle_timeout => 3600,
            :goto_table => TABLE_NETWORK_DST_CLASSIFIER
          }))
      @dp_info.add_flow(flow)

      messages = @arp_lookup[:requests].delete(message.arp_spa) || return

      if messages.first && messages.first[:destination_ipv4]
        flow = Flow.create(TABLE_ARP_LOOKUP, 25,
          match_md.merge({ :eth_type => 0x0800,
              :ipv4_dst => messages.first[:destination_ipv4].mask(messages.first[:destination_prefix]),
              :ipv4_dst_mask => IPV4_BROADCAST.mask(messages.first[:destination_prefix]),
            }), {
            :eth_dst => message.arp_sha
          },
          reflection_md.merge!({ :cookie => cookie,
              :idle_timeout => 3600,
              :goto_table => TABLE_NETWORK_DST_CLASSIFIER
            }))
        @dp_info.add_flow(flow)
      end

      arp_lookup_send_packets(messages)
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

      Celluloid::Actor.current.after([params[:attempts], 10].min) {
        params[:attempts] = params[:attempts] + 1
        arp_lookup_process_timeout(params)
      }

      debug log_format('arp_lookup: process timeout',
                       "ipv4_dst:#{params[:request_ipv4]} attempts:#{params[:attempts]}")

      packet_arp_out({ :out_port => OFPP_TABLE,
                       :in_port => OFPP_CONTROLLER,
                       :eth_src => params[:interface_mac],
                       :op_code => Racket::L3::ARP::ARPOP_REQUEST,
                       :sha => params[:interface_mac],
                       :spa => params[:interface_ipv4],
                       :tpa => params[:request_ipv4]
                     })
    end

    def arp_lookup_datapath_lookup(params)
      messages = @arp_lookup[:requests][params[:request_ipv4]]

      if messages.nil? || Time.now - messages.last[:timestamp] > 5.0
        debug log_format_h('arp_lookup_datapath_lookup: skipping lookup', params)

        @arp_lookup[:requests].delete(params[:request_ipv4])
        return
      end

      debug log_format_h('arp_lookup_datapath_lookup: looking up in database', params)

      # TODO: When we've received above a certain number of packets,
      # add a flow to drop packets before they get passed to the
      # controller.

      # Remove old packets...
      messages.select! { |message| Time.now - message[:timestamp] < 30.0 }

      Celluloid::Actor.current.after([params[:attempts], 10].min) {
        params[:attempts] = params[:attempts] + 1
        arp_lookup_process_timeout(params)
      }

      filter_args = {
        :ip_addresses__network_id => params[:interface_network_id],
        :ip_addresses__ipv4_address => params[:request_ipv4].to_i
      }
      ip_lease = MW::IpLease.batch.dataset.join_ip_addresses.where(filter_args).first.commit(:fill => [:interface,
                                                                                                       :ipv4_address,
                                                                                                       { :mac_lease => :mac_address }])

      if ip_lease.nil? || ip_lease.interface.nil?
        return unreachable_ip(messages, "no interface found", :no_interface)
      end

      debug log_format('packet_in, found ip lease', "cookie:0x%x ipv4:#{params[:request_ipv4]}" % @arp_lookup[:reply_cookie])

      # Load remote interface.
      interface = @dp_info.active_interface_manager.retrieve(interface_id: ip_lease.interface_id)

      debug log_format('packet_in, active interface', interface.inspect)

      # TODO: Check if interface is remote?

      flows = []
      flows << flow_create(table: TABLE_ARP_LOOKUP,
                           goto_table: TABLE_LOOKUP_IF_NW_TO_DP_NW,
                           priority: 35,

                           match: {
                             :eth_type => 0x0800,
                             :ipv4_dst => params[:request_ipv4]
                           },
                           match_network: params[:interface_network_id],

                           actions: {
                             :eth_dst => Pio::Mac.new(ip_lease.mac_lease.mac_address),
                           },

                           idle_timeout: 3600,

                           # Reflection based on metadata flag...
                           write_value_pair_flag: true,
                           write_value_pair_first: ip_lease.interface_id,
                           write_value_pair_second: params[:interface_network_id],

                           cookie: ip_lease.interface_id | COOKIE_TYPE_INTERFACE)

      @dp_info.add_flows(flows)

      arp_lookup_send_packets(@arp_lookup[:requests].delete(params[:request_ipv4]))
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

        @dp_info.send_packet_out(message[:message], OFPP_TABLE)
      }
    end

    #
    # Refactor...
    #

    def match_packet(message)
      # Verify metadata is a network type.

      match = md_create(:network => message.match.metadata & METADATA_VALUE_MASK)
      match.merge!({ :eth_type => 0x0800,
                     :ipv4_dst => message.ipv4_dst
                   })
    end

    def unreachable_ip(messages, error_msg, suppress_reason)
      message = messages.last[:message]
      return if message.nil?

      debug log_format("packet_in, error '#{error_msg}'",
                       "cookie:0x%x ipv4:#{message.ipv4_dst}" % message.cookie)

      suppress_packets(message, suppress_reason)
      nil
    end

    def suppress_packets(message, reason)
      # These should set us as listeners to events for the interface
      # becoming active or IP address being leased.
      case reason
      when :no_route           then hard_timeout = 30
      when :no_interface       then hard_timeout = 30
      when :inactive_interface then hard_timeout = 10
      end

      flow = Flow.create(TABLE_ARP_LOOKUP, 21,
                         match_packet(message),
                         nil, {
                           :cookie => message.cookie,
                           :hard_timeout => hard_timeout
                         })

      @dp_info.add_flow(flow)
    end

  end

end
