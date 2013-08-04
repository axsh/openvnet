# -*- coding: utf-8 -*-

require 'racket'

module Vnet::Openflow::Services

  class ArpLookup < Base

    def initialize(params)
      super
      # @entries = {}

      @network_id = params[:network_id]
      @network_uuid = params[:network_uuid]
      @network_type = params[:network_type]
      @vif_uuid = params[:vif_uuid]
      @service_mac = params[:service_mac]
      @service_ipv4 = params[:service_ipv4]
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

    def packet_in(port, message)
      if message.eth_type == 0x0806
        debug "service::arp_lookup.packet_in: port_no:#{port.port_info.port_no} name:#{port.port_info.name} arp_spa:#{message.arp_spa}"

        network_md = md_create({ :network => @network_id,
                                 @network_type => nil
                               })
        cookie = @network_id | (COOKIE_PREFIX_NETWORK << COOKIE_PREFIX_SHIFT)

        flow = Flow.create(TABLE_ARP_LOOKUP, 25,
                           network_md.merge({ :eth_type => 0x0800,
                                              :ipv4_dst => message.arp_spa
                                            }), {
                             :eth_dst => message.arp_sha
                           }, {
                             :cookie => cookie,
                             :goto_table => TABLE_PHYSICAL_DST
                           })

        @datapath.add_flow(flow)        

      else
        debug "service::arp_lookup.packet_in: port_no:#{port.port_info.port_no} name:#{port.port_info.name} ipv4_dst:#{message.ipv4_dst}"

        arp_out({ :out_port => OFPP_TABLE,
                  :in_port => OFPP_LOCAL,
                  :eth_src => @service_mac,
                  :op_code => Racket::L3::ARP::ARPOP_REQUEST,
                  :sha => @service_mac,
                  :spa => @service_ipv4,
                  :tpa => message.ipv4_dst
                })
      end
    end

  end

end
