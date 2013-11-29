# -*- coding: utf-8 -*-

module Vnet::Openflow
  class ConnectionManager < Manager
    include Vnet::Openflow::FlowHelpers
    include Celluloid::Logger

    COOKIE_TAG_CATCH_FLOW         = 0x1 << COOKIE_TAG_SHIFT
    COOKIE_TAG_INGRESS_CONNECTION = 0x2 << COOKIE_TAG_SHIFT

    def packet_in(message)
      open_connection(message)
    end

    def catch_flow_cookie(interface)
      COOKIE_TYPE_CONTRACK | COOKIE_TAG_CATCH_FLOW | interface.id
    end

    def catch_new_egress(interface, mac_info, ipv4_info)
      flows = [IPV4_PROTOCOL_TCP, IPV4_PROTOCOL_UDP].map { |protocol|
        flow_create(:default,
                    table: TABLE_INTERFACE_EGRESS_FILTER,
                    priority: 20,
                    match: {
                      eth_src: mac_info[:mac_address],
                      eth_type: ETH_TYPE_IPV4,
                      ip_proto: protocol
                    },
                    cookie: catch_flow_cookie(interface),
                    actions: { output: Controller::OFPP_CONTROLLER })
      }

      @dp_info.add_flows(flows)
    end

    def remove_catch_new_egress(interface)
      @dp_info.del_cookie catch_flow_cookie(interface)
    end

    def close_connections(interface)
      debug log_format("Closing all connections for interface '#{interface.uuid}'")
      @dp_info.del_cookie Connections::Base.cookie(interface.id)
    end

    def open_connection(message)
      flows = if message.tcp?
        Connections::TCP.new.open(message)
      elsif message.udp?
        Connections::UDP.new.open(message)
      end

      @dp_info.add_flows(flows)
      @dp_info.send_packet_out(message, OFPP_TABLE)
    end

  end
end
