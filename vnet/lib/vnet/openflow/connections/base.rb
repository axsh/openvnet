# -*- coding: utf-8 -*-

module Vnet::Openflow::Connections
  class Base
    include Vnet::Openflow::FlowHelpers
    include Celluloid::Logger

    CM = Vnet::Openflow::ConnectionManager

    EGRESS_IDLE_TIMEOUT  = 550
    INGRESS_IDLE_TIMEOUT = 600

    def self.cookie(interface_id)
      COOKIE_TYPE_CONTRACK | CM::COOKIE_TAG_INGRESS_CONNECTION | interface_id
    end

    def cookie(interface_id)
      self.class.cookie(interface_id)
    end

    def open(message)
      interface_id = message.cookie & COOKIE_ID_MASK

      # Log messages for connections are disabled by default since they
      # require database access which is too expensive.
      # They can be enabled by writing the following in vna.conf
      # security_groups { log_connection_tracking true }
      if Vnet::Configurations::Vna.conf.security_groups.log_connection_tracking
        interface = MW::Interface.batch[interface_id].commit
        log_new_open(interface, message)
      end

      [
        flow_create(:default,
                    table: TABLE_INTERFACE_EGRESS_FILTER,
                    priority: 21,
                    match: {
                      eth_src:   message.packet_info.eth_src,
                      eth_type: message.eth_type,
                      ipv4_src: message.ipv4_src,
                      ipv4_dst: message.ipv4_dst,
                    }.merge(match_egress(message)),
                    idle_timeout: EGRESS_IDLE_TIMEOUT,
                    cookie: cookie(interface_id),
                    goto_table: TABLE_NETWORK_SRC_CLASSIFIER),
        flow_create(:default,
                    table: TABLE_INTERFACE_INGRESS_FILTER_LOOKUP,
                    priority: 10,
                    match: {
                      eth_dst:   message.packet_info.eth_src,
                      eth_type: ETH_TYPE_IPV4,
                      ipv4_src:   message.ipv4_dst,
                      ipv4_dst:   message.ipv4_src,
                    }.merge(match_ingress(message)),
                    match_metadata: { interface: interface_id },
                    idle_timeout: INGRESS_IDLE_TIMEOUT,
                    cookie: cookie(interface_id),
                    goto_table: TABLE_INTERFACE_VIF)
      ]
    end

    def log_new_open(interface, message)
      # Override with a log message if you want to
    end

    def match_egress(message)
      raise NotImplementedError, "match_egress"
    end

    def match_ingress(message)
      raise NotImplementedError, "match_ingress"
    end
  end
end
