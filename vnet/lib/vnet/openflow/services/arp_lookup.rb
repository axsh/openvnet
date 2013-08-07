# -*- coding: utf-8 -*-

require 'racket'

module Vnet::Openflow::Services

  class ArpLookup < Base
    include Celluloid

    def initialize(params)
      super

      @network_id = params[:network_id]
      @network_uuid = params[:network_uuid]
      @network_type = params[:network_type]
      @vif_uuid = params[:vif_uuid]
      @service_mac = params[:service_mac]
      @service_ipv4 = params[:service_ipv4]

      @requests = {}
    end

    def install
      debug "service::arp_lookup.insert: network:#{@network_uuid}/#{@network_id} vif_uuid:#{@vif_uuid}"

      return if @network_type != :physical

      catch_flow(:network, {
                   :eth_dst => @service_mac,
                   :eth_type => 0x0806,
                   :arp_op => 2,
                   :arp_tha => @service_mac,
                   :arp_tpa => @service_ipv4
                 }, {
                   :network_id => @network_id,
                   :network_type => @network_type
                 })
      catch_flow(:arp_lookup, {
                   :eth_src => @service_mac,
                   :eth_type => 0x0800
                 }, {
                   :network_id => @network_id,
                   :network_type => @network_type
                 })
    end

    def packet_in(message)
      port_number = message.match.in_port

      if message.eth_type == 0x0806
        debug "service::arp_lookup.packet_in: port_number:#{port_number} arp_spa:#{message.arp_spa}"

        match_md = md_create({ :network => @network_id,
                               @network_type => nil
                             })
        reflection_md = md_create(:reflection => nil)

        cookie = @network_id | (COOKIE_PREFIX_NETWORK << COOKIE_PREFIX_SHIFT)

        flow = Flow.create(TABLE_ARP_LOOKUP, 25,
                           match_md.merge({ :eth_type => 0x0800,
                                            :ipv4_dst => message.arp_spa
                                          }), {
                             :eth_dst => message.arp_sha
                           },
                           reflection_md.merge!({ :cookie => cookie,
                                                  :idle_timeout => 3600,
                                                  :goto_table => TABLE_PHYSICAL_DST
                                                }))

        @datapath.add_flow(flow)        

        send_packets(@requests.delete(message.arp_spa))

      else
        debug "service::arp_lookup.packet_in: port_number:#{port_number} ipv4_dst:#{message.ipv4_dst}"

        # Check if the address is in the same network, or if we need
        # to look up a gateway mac address.
        request_ipv4 = message.ipv4_dst

        messages = @requests[request_ipv4] ||= []
        messages << {
          :message => message,
          :timestamp => Time.now
        }

        process_timeout(request_ipv4, 1) if messages.size == 1

        messages.drop(5) if messages.size > 20
      end
    end

    def process_timeout(request_ipv4, attempts)
      messages = @requests[request_ipv4]

      if messages.nil? || Time.now - messages.last[:timestamp] > 5.0
        @requests.delete(request_ipv4)
        return
      end

      # TODO: When we've received above a certain number of packets,
      # add a flow to drop packets before they get passed to the
      # controller.

      # Remove old packets...
      messages.select! { |message| Time.now - message[:timestamp] < 30.0 }

      after([attempts, 10].min) { process_timeout(request_ipv4, attempts + 1) }

      debug "service::arp_lookup: process timeout (ipv4_dst:#{request_ipv4} attempts:#{attempts})"

      arp_out({ :out_port => OFPP_TABLE,
                :in_port => OFPP_LOCAL,
                :eth_src => @service_mac,
                :op_code => Racket::L3::ARP::ARPOP_REQUEST,
                :sha => @service_mac,
                :spa => @service_ipv4,
                :tpa => request_ipv4
              })
    end

    def send_packets(messages)
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
