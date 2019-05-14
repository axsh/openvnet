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
      flows << flow_create(table: TABLE_OUT_PORT_INGRESS_IF_NIL,
                           priority: 30,
                           
                           match: {
                             :eth_type => 0x0806,
                             :arp_op => 2,
                           },
                           match_first: @arp_lookup[:interface_id],

                           actions: {
                             :output => :controller
                           },

                           cookie: @arp_lookup[:reply_cookie])
    end

    def arp_lookup_ipv4_flows(flows, mac_info, ipv4_info)
      ipv4_info_mask = ipv4_info[:network_prefix]
      mac_address = mac_info[:mac_address]

      [ [20, {
            :eth_src => mac_address,
            :eth_type => 0x0800
          }],
        [30, {
            :eth_src => mac_address,
            :eth_type => 0x0800,
            :ipv4_dst => ipv4_info[:ipv4_address].mask(ipv4_info_mask),
            :ipv4_dst_mask => IPV4_BROADCAST.mask(ipv4_info_mask)
          }],
        [40, {
            :eth_src => mac_address,
            :eth_type => 0x0800,
            :ipv4_src => ipv4_info[:ipv4_address].mask(ipv4_info_mask),
            :ipv4_src_mask => IPV4_BROADCAST.mask(ipv4_info_mask),
            :ipv4_dst => ipv4_info[:ipv4_address].mask(ipv4_info_mask),
            :ipv4_dst_mask => IPV4_BROADCAST.mask(ipv4_info_mask)
          }],
      ].each { |priority, match|
        flows << flow_create(table: TABLE_ARP_LOOKUP_NW_NIL,
                             priority: priority,
                             
                             match: match,
                             #match_remote: FLAG_NO_CONTROLLER,
                             match_first: ipv4_info[:network_id],

                             actions: {
                               :output => :controller
                             },

                             cookie: @arp_lookup[:lookup_cookie])
      }
    end

    def arp_lookup_lookup_packet_in(message)
      port_number = message.match.in_port

      # Check if the address is in the same network, or if we need
      # to look up a gateway mac address.
      request_ipv4 = message.ipv4_dst

      # TODO: This should be done every time process_timeout is called...

      # TODO: Currently relies on metadata to identify the
      # network. For n-hop routing, figure out when the a gateway /
      # route should be looked up.

      mac_info, ipv4_info, network = get_mac_ipv4_network(message.ipv4_src)

      # When the source ipv4 address belongs to the simulated
      # interface we need to match it in TABLE_ARP_LOOKUP_NW_NIL so that each
      # ip lease used is forced to do an arp request. This ensures
      # that the external interface sends us an arp request.
      use_src_ipv4 = network && message.ipv4_src

      if network.nil?
        mac_info, ipv4_info, network = get_mac_ipv4_network(nil)
      end

      if network.nil?
        debug log_format_h('arp_lookup_lookup_packet_in failed',
                           port_number: port_number,
                           request_ipv4: request_ipv4,
                           ipv4_src: message.ipv4_src,
                           ipv4_dst: message.ipv4_dst)
        return
      end

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
        :destination_prefix => destination_prefix,
        :use_src_ipv4 => use_src_ipv4,
      }

      if messages.size == 1
        # Remove virtual network mode's use of db lookup until arp
        # lookup has been refactored, as the db lookups as-is won't
        # work with the active interface refactoring.

        debug log_format_h('arp_lookup_lookup_packet_in looking up',
                           port_number: port_number,
                           interface_ipv4: ipv4_info[:ipv4_address],
                           network_type: ipv4_info[:network_type],
                           request_ipv4: request_ipv4,
                           ipv4_src: message.ipv4_src,
                           ipv4_dst: message.ipv4_dst)

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

      else
        debug log_format_h('arp_lookup_lookup_packet_in added to queue',
                           port_number: port_number,
                           interface_ipv4: ipv4_info[:ipv4_address],
                           request_ipv4: request_ipv4,
                           ipv4_src: message.ipv4_src,
                           ipv4_dst: message.ipv4_dst,
                           messages_size: messages.size)
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

      mac_info, ipv4_info = get_mac_ipv4(message.arp_tpa)

      if mac_info.nil? || ipv4_info.nil?
        debug log_format_h('arp_lookup_reply_packet_in ip lease not found',
                           port_number: port_number,
                           arp_spa: message.arp_spa,
                           arp_tpa: message.arp_tpa)
        return
      end

      [ [35, {}],
        [45, { ipv4_src: message.arp_tpa } ]
      ].each { |priority, match_extra|
        flow = flow_create(table: TABLE_ARP_LOOKUP_NW_NIL,
                           goto_table: TABLE_NETWORK_DST_CLASSIFIER_NW_NIL,
                           priority: priority,
                           idle_timeout: 3600,

                           match: {
                             eth_type: 0x0800,
                             ipv4_dst: message.arp_spa,
                           },
                           match_first: ipv4_info[:network_id],

                           write_reflection: true,

                           actions: {
                             eth_dst: message.arp_sha,
                           },

                           cookie: ipv4_info[:network_id] | COOKIE_TYPE_NETWORK,
                          )

        @dp_info.add_flow(flow)
      }

      messages = @arp_lookup[:requests].delete(message.arp_spa)

      if messages.nil?
        debug log_format_h('arp_lookup_reply_packet_in no messages found',
                           port_number: port_number,
                           arp_spa: message.arp_spa,
                           arp_tpa: message.arp_tpa)
        return
      end

      # TODO: This might have issues as it only does the first message...
      messages.first.tap { |queued_message|
        next if queued_message[:destination_ipv4].nil?

        flows = []

        # TODO: Review.
        flow = flow_create(table: TABLE_ARP_LOOKUP_NW_NIL,
                           goto_table: TABLE_NETWORK_DST_CLASSIFIER_NW_NIL,
                           priority: 25,
                           idle_timeout: 3600,

                           match: {
                             eth_type: 0x0800,
                             :ipv4_dst => queued_message[:destination_ipv4].mask(queued_message[:destination_prefix]),
                             :ipv4_dst_mask => IPV4_BROADCAST.mask(queued_message[:destination_prefix]),
                           },
                           match_first: ipv4_info[:network_id],

                           actions: {
                             eth_dst: message.arp_sha,
                           },
                           write_reflection: true,

                           cookie: ipv4_info[:network_id] | COOKIE_TYPE_NETWORK,
                          )

        # if queued_message[:use_src_ipv4]
        #   flows << Flow.create(TABLE_ARP_LOOKUP_NW_NIL, 45,
        #     match_md.merge({ :eth_type => 0x0800,
        #         :ipv4_src => queued_message[:use_src_ipv4],
        #         :ipv4_dst => queued_message[:destination_ipv4].mask(queued_message[:destination_prefix]),
        #         :ipv4_dst_mask => IPV4_BROADCAST.mask(queued_message[:destination_prefix]),
        #       }), {
        #       :eth_dst => message.arp_sha
        #     },
        #     reflection_md.merge!({ :cookie => cookie,
        #         :idle_timeout => 3600,
        #         :goto_table => TABLE_NETWORK_DST_CLASSIFIER
        #       }))
        # end

        @dp_info.add_flows(flows)
      }

      debug log_format_h('arp_lookup_reply_packet_in send messages',
                         port_number: port_number,
                         arp_spa: message.arp_spa,
                         arp_tpa: message.arp_tpa,
                         messages_size: messages.size,
                         messages_first_ipv4: messages.first && messages.first[:destination_ipv4])

      arp_lookup_send_packets(messages)
    end

    def arp_lookup_process_timeout(params)
      messages = @arp_lookup[:requests][params[:request_ipv4]]

      if messages.nil? || Time.now - messages.last[:timestamp] > 5.0
        debug log_format_h('arp_lookup_process_timeout: deleting message queue',
                           interface_ipv4: params[:interface_ipv4],
                            request_ipv4: params[:request_ipv4],
                            attempts: params[:attempts],
                            messages: messages && messages.size)

        @arp_lookup[:requests].delete(params[:request_ipv4])
        return
      end

      # TODO: When we've received above a certain number of packets,
      # add a flow to drop packets before they get passed to the
      # controller.

      # Remove old packets...
      messages.select! { |message| Time.now - message[:timestamp] < 30.0 }

      Celluloid::Actor.current.after([params[:attempts], 10].min) {
        params[:attempts] += 1
        arp_lookup_process_timeout(params)
      }

      debug log_format_h('arp_lookup_process_timeout: packet_arp_out',
                         interface_ipv4: params[:interface_ipv4],
                         request_ipv4: params[:request_ipv4],
                         attempts: params[:attempts])

      packet_arp_out({ out_port: OFPP_TABLE,
                       in_port: Pio::OpenFlow13::Port32.reserved_port_number(:controller),
                       eth_src: params[:interface_mac],
                       op_code: Racket::L3::ARP::ARPOP_REQUEST,
                       sha: params[:interface_mac],
                       spa: params[:interface_ipv4],
                       tpa: params[:request_ipv4]
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

      # TODO: Send arp only when simulated interface is part of a
      # specific datapath.
      # Celluloid::Actor.current.after([params[:attempts], 10].min) {
      #   params[:attempts] += 1
      #   arp_lookup_process_timeout(params)
      # }

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

      debug log_format_h('packet_in, found ip lease',
                         cookie: "0x%x" % @arp_lookup[:reply_cookie],
                         request_ipv4: params[:request_ipv4])

      # Load remote interface.
      interface = @dp_info.active_interface_manager.retrieve(interface_id: ip_lease.interface_id)

      debug log_format('packet_in, active interface', interface.inspect)

      # TODO: Check if interface is remote?

      flows = []
      flows << flow_create(table: TABLE_ARP_LOOKUP_NW_NIL,
                           goto_table: TABLE_LOOKUP_IF_NW,
                           priority: 35,
                           idle_timeout: 3600,

                           match: {
                             :eth_type => 0x0800,
                             :ipv4_dst => params[:request_ipv4]
                           },
                           match_first: params[:interface_network_id],

                           write_reflection: true,
                           write_first: ip_lease.interface_id,
                           write_second: params[:interface_network_id],

                           actions: {
                             :eth_dst => Pio::Mac.new(ip_lease.mac_lease.mac_address),
                           },
                           cookie: ip_lease.interface_id | COOKIE_TYPE_INTERFACE)

      @dp_info.add_flows(flows)

      arp_lookup_send_packets(@arp_lookup[:requests].delete(params[:request_ipv4]))
    end

    def arp_lookup_send_packets(messages)
      return if messages.nil?

      messages.each { |message|
        # Set the in_port to :controller since the packets stored
        # have already been processed by TABLE_CLASSIFIER to
        # TABLE_ARP_LOOKUP_NW_NIL, and as such no longer match the fields
        # required by the old in_port.
        #
        # The route link is identified by eth_dst, which was set in
        # TABLE_ROUTER_LINK prior to be sent to the controller.
        message[:message].match.in_port = :controller

        @dp_info.send_packet_out(message[:message], OFPP_TABLE)
      }
    end

    def match_for_network_metadata(message)
      case message.table_id
      when TABLE_ARP_LOOKUP_NW_NIL
        { match_first: (message.match.metadata & METADATA_FIRST_MASK) >> 32 }
      else
        raise "arp_lookup match_for_network_metadata does not support table_id #{message.table_id}"

        error log_format("arp_lookup match_packet does not support table_id", table_id: message.table_id)
        nil
      end
    end

    #
    # Refactor...
    #

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

      match_for_network_metadata(message).tap { |match_network|
        if match_network.nil?
          debug log_format("arp_lookup suppress_packets received packet with unknown table id")
          return
        end

        flow_hash = {
          table: TABLE_ARP_LOOKUP_NW_NIL,
          priority: 21,
          hard_timeout: hard_timeout,

          match: { eth_type: 0x0800,
                   ipv4_dst: message.ipv4_dst,
                 },

          cookie: message.cookie,
        }.merge(match_network)

        @dp_info.add_flow(flow_create(flow_hash))
      }
    end

  end

end
