# -*- coding: utf-8 -*-

module Vnet::Openflow::Translations

  class StaticAddress < Base

    def initialize(params)
      super

      @static_addresses = {}
    end

    def log_type
      'translation/static_address'
    end

    def install
      return if @interface_id.nil?

      flows = []
      flows_for_enable_passthrough(flows) if @passthrough == true

      @static_addresses.each { |id, translation|
        debug log_format('install translation flow', translation.inspect)

        flows_for_translation(flows, translation)
      }

      @dp_info.add_flows(flows)
    end

    def added_static_address(static_address_id, route_link_id, ingress_ipv4_address, egress_ipv4_address)
      translation = {
        :static_address_id => static_address_id,
        :route_link_id => route_link_id,
        :ingress_ipv4_address => IPAddr.new(ingress_ipv4_address, Socket::AF_INET),
        :egress_ipv4_address => IPAddr.new(egress_ipv4_address, Socket::AF_INET),
      }
      @static_addresses[static_address_id] = translation

      return if @installed == false

      flows = []
      flows_for_translation(flows, translation)

      @dp_info.add_flows(flows)
    end

    def removed_static_address(static_address_id, ingress_ipv4_address, egress_ipv4_address)
      translation = @static_addresses.delete(static_address_id)

      return if @installed == false

      @dp_info.del_flows(table_id: TABLE_ROUTE_INGRESS_TRANSLATION,
                         cookie: self.cookie,
                         cookie_mask: self.cookie_mask,
                         match: Trema::Match.new(eth_type: ETH_TYPE_IPV4,
                                                 ipv4_dst: ingress_ipv4_address))
      @dp_info.del_flows(table_id: TABLE_ROUTE_EGRESS_TRANSLATION,
                         cookie: self.cookie,
                         cookie_mask: self.cookie_mask,
                         match: Trema::Match.new(eth_type: ETH_TYPE_IPV4,
                                                 ipv4_src: egress_ipv4_address))
    end

    #
    # Internal methods:
    #

    private

    def flows_for_enable_passthrough(flows)
      [[TABLE_ROUTE_INGRESS_TRANSLATION, TABLE_ROUTER_INGRESS_LOOKUP],
       [TABLE_ROUTE_EGRESS_TRANSLATION, TABLE_ROUTE_EGRESS_INTERFACE]
      ].each { |table, goto_table|
        flows << flow_create(:default,
                             table: table,
                             goto_table: goto_table,
                             priority: 10,

                             match_interface: @interface_id)
      }
    end

    def flows_for_translation(flows, translation)
      ingress_flow_options = {
        table: TABLE_ROUTE_INGRESS_TRANSLATION,
        priority: 50,

        match: {
          :eth_type => ETH_TYPE_IPV4,
          :ipv4_dst => translation[:ingress_ipv4_address],
        },
        match_interface: @interface_id,

        actions: {
          :ipv4_dst => translation[:egress_ipv4_address],
        }
      }

      egress_flow_options = {
        priority: 50,
        match: {
          :eth_type => ETH_TYPE_IPV4,
          :ipv4_src => translation[:egress_ipv4_address],
        },
        actions: {
          :ipv4_src => translation[:ingress_ipv4_address],
        }
      }

      if translation[:route_link_id]
        ingress_flow_options[:goto_table] = TABLE_ROUTER_CLASSIFIER
        ingress_flow_options[:write_route_link] = translation[:route_link_id]
        ingress_flow_options[:write_reflection] = true

        egress_flow_options[:table] = TABLE_ROUTE_EGRESS_LOOKUP
        egress_flow_options[:goto_table] = TABLE_ROUTE_EGRESS_INTERFACE
        egress_flow_options[:match_value_pair_first] = @interface_id
        egress_flow_options[:match_value_pair_second] = translation[:route_link_id]
        egress_flow_options[:clear_all] = true
        egress_flow_options[:write_reflection] = true
        egress_flow_options[:write_interface] = @interface_id
      else
        ingress_flow_options[:goto_table] = TABLE_ROUTER_INGRESS_LOOKUP

        egress_flow_options[:table] = TABLE_ROUTE_EGRESS_TRANSLATION
        egress_flow_options[:goto_table] = TABLE_ROUTE_EGRESS_INTERFACE
        egress_flow_options[:match_interface] = @interface_id
      end

      flows << flow_create(:default, ingress_flow_options)
      flows << flow_create(:default, egress_flow_options)
    end

  end

end
