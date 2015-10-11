# -*- coding: utf-8 -*-

module Vnet::Core::Translations

  class StaticAddress < Base

    def initialize(params)
      super

      @static_addresses = {}
    end

    def log_type
      'translation/static_address'
    end

    def valid_translation?(translation)
      return false if translation[:ingress_port_number].nil? != translation[:egress_port_number].nil?
      true
    end

    def pretty_static_address(sa_tr)
      "sa_id:#{sa_tr[:static_address_id]}" +
        (sa_tr[:route_link_id] ? " route_link_id:#{sa_tr[:route_link_id]}" : '') +
        " ipv4_address:#{sa_tr[:ingress_ipv4_address]}->#{sa_tr[:egress_ipv4_address]}" +
        (sa_tr[:ingress_port_number] || sa_tr[:egress_port_number] ?
         " port:#{sa_tr[:ingress_port_number]}->#{sa_tr[:egress_port_number]}" : '')
    end

    def install
      return if @interface_id.nil?

      flows = []
      flows_for_enable_passthrough(flows) if @passthrough == true

      @static_addresses.each { |id, translation|
        debug log_format('installing translation for ' + self.pretty_id,
                         pretty_static_address(translation))
                         
        next unless valid_translation?(translation)

        flows_for_ingress_translation(flows, translation)
        flows_for_egress_translation(flows, translation)
      }

      @dp_info.add_flows(flows)
    end

    def added_static_address(static_address_id,
                             route_link_id,
                             ingress_ipv4_address,
                             egress_ipv4_address,
                             ingress_port_number,
                             egress_port_number)
      translation = {
        :static_address_id => static_address_id,
        :route_link_id => route_link_id,
        :ingress_ipv4_address => IPAddr.new(ingress_ipv4_address, Socket::AF_INET),
        :egress_ipv4_address => IPAddr.new(egress_ipv4_address, Socket::AF_INET),
        :ingress_port_number => ingress_port_number,
        :egress_port_number => egress_port_number,
      }
      @static_addresses[static_address_id] = translation

      return if @installed == false
      return unless valid_translation?(translation)

      flows = []
      flows_for_ingress_translation(flows, translation)
      flows_for_egress_translation(flows, translation)

      @dp_info.add_flows(flows)
    end

    def removed_static_address(static_address_id)
      translation = @static_addresses.delete(static_address_id)

      return if @installed == false
      return unless valid_translation?(translation)

      # TODO: Fix del flow for route link translation...

      match_actions_for_ingress(translation).each { |match, actions|
        routing_table_base_indices.each { |table_base|
          @dp_info.del_flows(table_id: table_base + TABLEN_ROUTE_INGRESS_TRANSLATION,
                             cookie: self.cookie,
                             cookie_mask: self.cookie_mask,
                             match: match)
        }
      }
      match_actions_for_egress(translation).each { |match, actions|
        routing_table_base_indices.each { |table_base|
          @dp_info.del_flows(table_id: table_base + TABLEN_ROUTE_EGRESS_TRANSLATION,
                             cookie: self.cookie,
                             cookie_mask: self.cookie_mask,
                             match: match)
        }
      }
    end

    #
    # Internal methods:
    #

    private

    def match_actions_for_ingress(translation)
      ingress_port_number = translation[:ingress_port_number]

      if ingress_port_number
        [[{ eth_type: ETH_TYPE_IPV4,
            ipv4_dst: translation[:ingress_ipv4_address],
            ip_proto: IPV4_PROTOCOL_TCP,
            tcp_dst: ingress_port_number
          }, {
            ipv4_dst: translation[:egress_ipv4_address],
            tcp_dst: translation[:egress_port_number],
          }],
         [{ eth_type: ETH_TYPE_IPV4,
            ipv4_dst: translation[:ingress_ipv4_address],
            ip_proto: IPV4_PROTOCOL_UDP,
            udp_dst: ingress_port_number
          }, {
            ipv4_dst: translation[:egress_ipv4_address],
            udp_dst: translation[:egress_port_number],
          }]]
      else
        [[{ eth_type: ETH_TYPE_IPV4,
            ipv4_dst: translation[:ingress_ipv4_address]
          }, {
            ipv4_dst: translation[:egress_ipv4_address],
          }]]
      end
    end

    def match_actions_for_egress(translation)
      egress_port_number = translation[:egress_port_number]

      if egress_port_number
        [[{ eth_type: ETH_TYPE_IPV4,
            ipv4_src: translation[:egress_ipv4_address],
            ip_proto: IPV4_PROTOCOL_TCP,
            tcp_src: egress_port_number
          }, {
            ipv4_src: translation[:ingress_ipv4_address],
            tcp_src: translation[:ingress_port_number],
          }],
         [{ eth_type: ETH_TYPE_IPV4,
            ipv4_src: translation[:egress_ipv4_address],
            ip_proto: IPV4_PROTOCOL_UDP,
            udp_src: egress_port_number
          }, {
            ipv4_src: translation[:ingress_ipv4_address],
            udp_src: translation[:ingress_port_number],
          }]]
      else
        [[{ eth_type: ETH_TYPE_IPV4,
            ipv4_src: translation[:egress_ipv4_address]
          }, {
            ipv4_src: translation[:ingress_ipv4_address]
          }]]
      end
    end

    def flows_for_enable_passthrough(flows)
      [[TABLEN_ROUTE_INGRESS_TRANSLATION, TABLEN_ROUTER_INGRESS_LOOKUP],
       [TABLEN_ROUTE_EGRESS_TRANSLATION, TABLEN_ROUTE_EGRESS_INTERFACE]
      ].each { |table_index, goto_table|
        routing_table_base_indices.each { |table_base|
          flows << flow_create(table: table_base + table_index,
                               goto_table: table_base + goto_table,
                               priority: 10,

                               match_interface: @interface_id)
        }
      }
    end

    def flows_for_ingress_translation(flows, translation)
      match_actions_for_ingress(translation).each { |match, actions|
        flow_options = {
          priority: 50,
          match: match,
          match_interface: @interface_id,
          actions: actions
        }

        if translation[:route_link_id]
          goto_table = TABLEN_ROUTER_CLASSIFIER
          flow_options[:write_route_link] = translation[:route_link_id]
          flow_options[:write_reflection] = true
        else
          goto_table = TABLEN_ROUTER_INGRESS_LOOKUP
        end

        routing_table_base_indices.each { |table_base|
          flow_options[:table] = table_base + TABLEN_ROUTE_INGRESS_TRANSLATION
          flow_options[:goto_table] = table_base + goto_table

          flows << flow_create(flow_options)
        }
      }
    end


    def flows_for_egress_translation(flows, translation)
      match_actions_for_egress(translation).each { |match, actions|
        flow_options = {
          priority: 50,
          match: match,
          actions: actions
        }

        # TODO: Move outside of block...
        if translation[:route_link_id]
          table_index = TABLEN_ROUTE_EGRESS_LOOKUP
          goto_table = TABLEN_ROUTE_EGRESS_INTERFACE
          flow_options[:match_value_pair_first] = @interface_id
          flow_options[:match_value_pair_second] = translation[:route_link_id]
          flow_options[:clear_all] = true
          flow_options[:write_reflection] = true
          flow_options[:write_interface] = @interface_id
        else
          table_index = TABLEN_ROUTE_EGRESS_TRANSLATION
          goto_table = TABLEN_ROUTE_EGRESS_INTERFACE
          flow_options[:match_interface] = @interface_id
        end

        routing_table_base_indices.each { |table_base|
          flow_options[:table] = table_base + table_index
          flow_options[:goto_table] = table_base + goto_table

          flows << flow_create(flow_options)
        }
      }
    end

  end

end
