# -*- coding: utf-8 -*-

module Vnet::Core::Routes

  class Base < Vnet::ItemDpUuid
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_reader :interface_id
    attr_reader :route_link_id
    attr_reader :network_id

    attr_reader :ipv4_address
    attr_reader :ipv4_prefix

    attr_reader :ingress
    attr_reader :egress

    attr_accessor :active_network
    attr_accessor :active_route_link

    def initialize(params)
      super

      map = params[:map]

      @interface_id = map.interface_id
      @route_link_id = map.route_link_id

      @network_id = map.network_id
      @ipv4_address = IPAddr.new(map.ipv4_network, Socket::AF_INET)
      @ipv4_prefix = map.ipv4_prefix

      @ingress = map.ingress
      @egress = map.egress

      @active_network = false
      @active_route_link = false
    end    
    
    def log_type
      'route/base'
    end

    def cookie
      @id | COOKIE_TYPE_ROUTE
    end

    def is_default_route
      is_ipv4_broadcast(@ipv4_address, @ipv4_prefix)
    end

    # Update variables by first duplicating to avoid memory
    # consistency issues with values passed to other actors.
    def to_hash
      Vnet::Core::Route.new(id: @id,
                            uuid: @uuid,

                            interface_id: @interface_id,
                            route_link_id: @route_link_id,
                            
                            network_id: @network_id,
                            ipv4_address: @ipv4_address,
                            ipv4_prefix: @ipv4_prefix,

                            ingress: @ingress,
                            egress: @egress)
    end

    #
    # Events:
    #

    def install
      return if
        @interface_id.nil? ||
        @network_id.nil? ||
        @route_link_id.nil?

      flows = []

      subnet_dst = match_ipv4_subnet_dst(@ipv4_address, @ipv4_prefix)
      subnet_src = match_ipv4_subnet_src(@ipv4_address, @ipv4_prefix)

      # Currently create these two flows even if the interface isn't
      # on this datapath. Should not cause any issues as the interface
      # id will never be matched.
      flows << flow_create(table: TABLE_INTERFACE_EGRESS_ROUTES,
                           goto_table: TABLE_INTERFACE_EGRESS_MAC,
                           priority: flow_priority,

                           match: subnet_dst,
                           match_interface: @interface_id,
                           write_network: @network_id)

      if @ingress == true
        flows << flow_create(table: TABLE_ROUTER_INGRESS_LOOKUP,
                             goto_table: TABLE_ROUTER_CLASSIFIER,
                             priority: flow_priority,

                             match: subnet_src,
                             match_interface: @interface_id,
                             write_route_link: @route_link_id,
                             write_reflection: true)
      end

      # In order to know what interface to egress from this flow needs
      # to be created even on datapaths where the interface is remote.
      if @egress == true
        flows << flow_create(
          table: TABLE_ROUTER_EGRESS_LOOKUP,
          goto_table: TABLE_ROUTE_EGRESS_LOOKUP,
          priority: flow_priority,

          match: subnet_dst,
          match_route_link: @route_link_id,

          write_value_pair_flag: false,
          write_value_pair_first: @interface_id,
          write_value_pair_second: @route_link_id)
      end

      @dp_info.add_flows(flows)
    end

    def uninstall
      @dp_info.del_cookie(self.cookie)
    end

    #
    # Internal methods:
    #

    private

    def flow_priority
      20 + @ipv4_prefix
    end

  end

end
