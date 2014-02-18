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

    def catch_flow_cookie(mac_lease_id)
      COOKIE_TYPE_CONNECTION | COOKIE_TAG_CATCH_FLOW | mac_lease_id
    end

    def catch_new_egress(mac_lease_id, mac_address)
      flows = [IPV4_PROTOCOL_TCP, IPV4_PROTOCOL_UDP].map { |protocol|
        flow_create(:default,
                    table: TABLE_INTERFACE_EGRESS_FILTER,
                    priority: 20,
                    match: {
                      eth_src: mac_address,
                      eth_type: ETH_TYPE_IPV4,
                      ip_proto: protocol
                    },
                    cookie: catch_flow_cookie(mac_lease_id),
                    actions: { output: Controller::OFPP_CONTROLLER })
      }

      @dp_info.add_flows(flows)
    end

    def remove_catch_new_egress(mac_lease_id)
      @dp_info.del_cookie catch_flow_cookie(mac_lease_id)
    end

    def close_connections(mac_lease_id)
      @dp_info.del_cookie Connections::Base.cookie(mac_lease_id)
    end

    def open_connection(message)
      flows = if message.tcp?
        log_new_connection("tcp", message)
        Connections::TCP.new.open(message)
      elsif message.udp?
        log_new_connection("udp", message)
        Connections::UDP.new.open(message)
      end

      @dp_info.add_flows(flows)
      @dp_info.send_packet_out(message, OFPP_TABLE)
    end

    private
    def log_new_connection(protocol, message)
      debug log_format("Opening new %s connection: (%s:%s => %s:%s)" %
        [protocol, message.ipv4_src, message.tcp_src, message.ipv4_dst, message.tcp_dst]
      )
    end

  end
end
