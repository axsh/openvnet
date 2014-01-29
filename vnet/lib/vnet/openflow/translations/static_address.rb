# -*- coding: utf-8 -*-

module Vnet::Openflow::Translations

  class StaticAddress < Base

    def initialize(params)
      super

      @static_addresses = {}

      return if params[:map].translate_static_addresses.nil?

      params[:map].translate_static_addresses.each { |translate|
        @static_addresses[translate.id] = {
          :id => translate.id,
          :ingress_ipv4_address => IPAddr.new(translate.ingress_ipv4_address, Socket::AF_INET),
          :egress_ipv4_address => IPAddr.new(translate.egress_ipv4_address, Socket::AF_INET),
        }
      }
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

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} translation/static_address: #{message}" + (values ? " (#{values})" : '')
    end

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
