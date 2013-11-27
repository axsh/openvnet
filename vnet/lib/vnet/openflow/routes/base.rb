# -*- coding: utf-8 -*-

module Vnet::Openflow::Routes

  class Base
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_reader :id
    attr_reader :uuid

    attr_reader :interface_id
    attr_reader :route_link_id
    attr_reader :route_link_mac_address

    attr_reader :network_id
    attr_reader :ipv4_address
    attr_reader :ipv4_prefix

    attr_reader :ingress
    attr_reader :egress

    attr_accessor :network_id
    attr_accessor :use_datapath_id

    def initialize(params)
      @dp_info = params[:dp_info]
      @manager = params[:manager]

      map = params[:map]

      @id = map.id
      @uuid = map.uuid

      @interface_id = map.interface_id
      @route_link_id = map.route_link_id
      @route_link_mac_address = params[:route_link_mac_address]

      @network_id = map.network_id
      @ipv4_address = IPAddr.new(map.ipv4_network, Socket::AF_INET)
      @ipv4_prefix = map.ipv4_prefix

      @ingress = map.ingress
      @egress = map.egress
    end    
    
    def cookie
      @id | COOKIE_TYPE_ROUTE
    end

    def is_default_route
      is_ipv4_broadcast(@ipv4_address, @ipv4_prefix)
    end

    #
    # Events:
    #

    def install
      return if
        @interface_id.nil? ||
        @network_id.nil? ||
        @route_link_id.nil? ||
        @route_link_mac_address.nil?

      flows = []

      subnet_dst = match_ipv4_subnet_dst(@ipv4_address, @ipv4_prefix)
      subnet_src = match_ipv4_subnet_src(@ipv4_address, @ipv4_prefix)

      if @use_datapath_id.nil?
        flows << flow_create(:routing,
                             table: TABLE_INTERFACE_EGRESS_ROUTES,
                             goto_table: TABLE_INTERFACE_EGRESS_MAC,

                             match: subnet_dst,
                             match_interface: @interface_id,
                             write_network: @network_id,
                             default_route: self.is_default_route,
                             cookie: cookie)

        if @ingress == true
          flows << flow_create(:routing,
                               table: TABLE_ROUTE_LINK_INGRESS,
                               goto_table: TABLE_ROUTE_LINK_EGRESS,

                               match: subnet_src,
                               match_interface: @interface_id,
                               write_route_link: @route_link_id,
                               default_route: self.is_default_route,
                               write_reflection: true,
                               cookie: cookie)
        end

        if @egress == true
          flows << flow_create(:routing,
                               table: TABLE_ROUTE_LINK_EGRESS,
                               goto_table: TABLE_ROUTE_EGRESS,

                               match: subnet_dst,
                               match_route_link: @route_link_id,
                               write_interface: @interface_id,
                               default_route: self.is_default_route,
                               cookie: cookie)
        end

      else
        if @egress == true
          [true, false].each { |reflection|

            # TODO: Instead use the interface ID as the second value,
            # and have a datapath:interface -> dp route link lookup
            # table.
            #
            # Add that table as a goto_table at the end where it jumps
            # to TABLE_LOOKUP_DP_ROUTE_LINK_IF, with mac set to rl mac.

            flows << flow_create(:routing,
                                 table: TABLE_ROUTE_LINK_EGRESS,
                                 goto_table: TABLE_LOOKUP_DP_RL_TO_DP_ROUTE_LINK,

                                 match: subnet_dst,
                                 match_reflection: reflection,
                                 match_route_link: @route_link_id,

                                 write_value_pair_flag: reflection,
                                 write_value_pair_first: @use_datapath_id,
                                 write_value_pair_second: @route_link_id,

                                 default_route: self.is_default_route,
                                 cookie: cookie)
          }

          # flows << flow_create(:routing,
          #                      table: TABLE_ROUTE_LINK_EGRESS,
          #                      goto_table: TABLE_ROUTE_EGRESS,

          #                      match: subnet_dst,
          #                      match_route_link: @route_link_id,

          #                      actions: {
          #                        :eth_dst => @route_link_mac_address
          #                      },
          #                      write_interface: @interface_id,
          #                      default_route: self.is_default_route,
          #                      cookie: cookie)
        end
      end

      @dp_info.add_flows(flows)
    end

    def uninstall
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} routes/base: #{message}" + (values ? " (#{values})" : '')
    end

  end

end
