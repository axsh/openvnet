# -*- coding: utf-8 -*-

module Vnet::Openflow::SecurityGroups::Connections
  SGM = Vnet::Openflow::SecurityGroupManager

  class Base
    include Vnet::Openflow::FlowHelpers
    include Celluloid::Logger

    def cookie(interface)
      interface.id |
      (COOKIE_PREFIX_SECURITY_GROUP << COOKIE_PREFIX_SHIFT) |
      (SGM::COOKIE_TAG_SG_CONTRACK << COOKIE_TAG_SHIFT)
    end

    def open(message)
      interface_id = message.cookie & COOKIE_ID_MASK
      interface = MW::Interface.batch[interface_id].commit

      #TODO: Write this as a single query despite model wrappers
      ip_addrs = MW::IpAddress.batch.filter(:ipv4_address => message.ipv4_src.to_i).all.commit
      ip_lease = MW::IpLease.batch.filter(
        :ip_address_id => ip_addrs.map {|ip| ip.id},
        :interface_id => interface_id).all.commit.first
      ip_addr = ip_addrs.find {|i| i.id == ip_lease.ip_address_id }
      network = MW::Network.batch[ip_addr.network_id].commit

      [
        flow_create(:default,
                    table: TABLE_VIF_PORTS,
                    priority: 21,
                    match: {
                      dl_src:   message.packet_info.eth_src,
                      eth_type: message.eth_type,
                      ipv4_src: message.ipv4_src,
                      ipv4_dst: message.ipv4_dst,
                    }.merge(match_egress(message)),
                    match_metadata: { interface: interface.id },
                    write_metadata: { network: network.id },
                    cookie: cookie(interface),
                    goto_table: TABLE_NETWORK_SRC_CLASSIFIER),
        flow_create(:default,
                    table: TABLE_INTERFACE_INGRESS_FILTER,
                    priority: 10,
                    cookie: cookie(interface),
                    match: {
                      dl_dst:   message.packet_info.eth_src,
                      eth_type: ETH_TYPE_IPV4,
                      ipv4_src:   message.ipv4_dst,
                      ipv4_dst:   message.ipv4_src,
                    }.merge(match_ingress(message)),
                    match_metadata: { interface: interface.id },
                    goto_table: TABLE_INTERFACE_VIF)
      ]
    end

    def match_egress(message)
      raise NotImplementedError, "match_egress"
    end

    def match_ingress(message)
      raise NotImplementedError, "match_ingress"
    end
  end

  class TCP < Base
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
