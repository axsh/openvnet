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
      return if
        @interface_id.nil?

      flows = []
      flows_for_disable_passthrough(flows) if @passthrough == false

      @static_addresses.each { |id, translate|
        debug log_format('install translate flow', translate.inspect)

        flows_for_translate(flows, translate)
      }

      @dp_info.add_flows(flows)
    end

    def uninstall
    end

    def added_static_address(static_address_id, ingress_ipv4_address, egress_ipv4_address)
      translation = {
        :static_address_id => static_address_id,
        :ingress_ipv4_address => IPAddr.new(ingress_ipv4_address, Socket::AF_INET),
        :egress_ipv4_address => IPAddr.new(egress_ipv4_address, Socket::AF_INET),
      }
      @static_addresses[static_address_id] = translation

      return if @installed == false

      flows = []
      flows_for_translate(flows, translation)

      @dp_info.add_flows(flows)
    end

    #
    # Internal methods:
    #

    private

    def flows_for_disable_passthrough(flows)
      flows << flow_create(:default,
                           table: TABLE_ROUTE_INGRESS_TRANSLATION,
                           priority: 10,

                           match_interface: @interface_id)
      flows << flow_create(:default,
                           table: TABLE_ROUTE_EGRESS_TRANSLATION,
                           priority: 10,

                           match_interface: @interface_id)
    end

    def flows_for_translate(flows, translate)
      flows << flow_create(:default,
                           table: TABLE_ROUTE_INGRESS_TRANSLATION,
                           goto_table: TABLE_ROUTER_INGRESS,
                           priority: 30,

                           match: {
                             :eth_type => ETH_TYPE_IPV4,
                             :ipv4_dst => translate[:ingress_ipv4_address],
                           },
                           match_interface: @interface_id,

                           actions: {
                             :ipv4_dst => translate[:egress_ipv4_address],
                           })
      flows << flow_create(:default,
                           table: TABLE_ROUTE_EGRESS_TRANSLATION,
                           goto_table: TABLE_ROUTE_EGRESS_INTERFACE,
                           priority: 30,

                           match: {
                             :eth_type => ETH_TYPE_IPV4,
                             :ipv4_src => translate[:egress_ipv4_address],
                           },
                           match_interface: @interface_id,

                           actions: {
                             :ipv4_src => translate[:ingress_ipv4_address],
                           })
    end

  end

end
