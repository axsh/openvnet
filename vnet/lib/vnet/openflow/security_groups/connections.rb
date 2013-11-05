# -*- coding: utf-8 -*-

module Vnet::Openflow::SecurityGroups::Connections
  SGM = Vnet::Openflow::SecurityGroupManager

  class Base
    include Vnet::Openflow::FlowHelpers
    include Celluloid::Logger

    IDLE_TIMEOUT = 600

    def cookie(interface_id)
      interface_id |
        COOKIE_TYPE_SECURITY_GROUP |
        SGM::COOKIE_SG_TYPE_TAG |
        SGM::COOKIE_TAG_CONTRACK
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
                      dl_src:   message.packet_info.eth_src,
                      eth_type: message.eth_type,
                      ipv4_src: message.ipv4_src,
                      ipv4_dst: message.ipv4_dst,
                    }.merge(match_egress(message)),
                    match_metadata: { interface: interface_id },
                    idle_timeout: IDLE_TIMEOUT,
                    cookie: cookie(interface_id),
                    goto_table: TABLE_INTERFACE_CLASSIFIER),
        flow_create(:default,
                    table: TABLE_INTERFACE_INGRESS_FILTER,
                    priority: 10,
                    match: {
                      dl_dst:   message.packet_info.eth_src,
                      eth_type: ETH_TYPE_IPV4,
                      ipv4_src:   message.ipv4_dst,
                      ipv4_dst:   message.ipv4_src,
                    }.merge(match_ingress(message)),
                    match_metadata: { interface: interface_id },
                    idle_timeout: IDLE_TIMEOUT,
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

  class TCP < Base
    def log_new_open(interface, message)
      debug "'%s' Opening new tcp connection %s:%s => %s:%s" %
        [interface.uuid, message.ipv4_src, message.tcp_src, message.ipv4_dst, message.tcp_dst]
    end

    def match_egress(message)
      {
        ip_proto: IPV4_PROTOCOL_TCP,
        tcp_src:  message.tcp_src,
        tcp_dst:  message.tcp_dst
      }
    end

    def match_ingress(message)
      {
        ip_proto: IPV4_PROTOCOL_TCP,
        tcp_src:  message.tcp_dst,
        tcp_dst:  message.tcp_src
      }
    end
  end

  # UDP is a connectionless protocol but we're not doing real connection
  # tracking here. When we send out a packet, we just open up the source port
  # so we can receive a reply.
  class UDP < Base
    def log_new_open(interface, message)
      debug "'%s' Opening new udp connection %s:%s => %s:%s" %
        [interface.uuid, message.ipv4_src, message.udp_src, message.ipv4_dst, message.udp_dst]
    end

    def match_egress(message)
      {
        ip_proto: IPV4_PROTOCOL_UDP,
        udp_src:  message.udp_src,
        udp_dst:  message.udp_dst
      }
    end

    def match_ingress(message)
      {
        ip_proto: IPV4_PROTOCOL_UDP,
        udp_src:  message.udp_dst,
        udp_dst:  message.udp_src
      }
    end
  end
end
