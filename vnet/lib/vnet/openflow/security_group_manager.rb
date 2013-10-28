# -*- coding: utf-8 -*-

module Vnet::Openflow
  class SecurityGroupManager < Manager
    include Vnet::Openflow::FlowHelpers

    def packet_in(message)
      case message.table_id
      when TABLE_INTERFACE_INGRESS_FILTER
        apply_rules(message)
      when TABLE_VIF_PORTS
        open_connection(message)
      end
    end

    def insert_catch_flow(interface)
      cookie = interface.id | (COOKIE_PREFIX_SECURITY_GROUP << COOKIE_PREFIX_SHIFT)
      flows = [
        flow_create(:default,
                    table: TABLE_INTERFACE_INGRESS_FILTER,
                    priority: 1,
                    match_metadata: { interface: interface.id },
                    cookie: cookie,
                    actions: { output: Controller::OFPP_CONTROLLER }),
        #TODO: Move this somewhere where it doens't get redone every time
        # a new interface is deployed.
        flow_create(:default,
                    table: TABLE_INTERFACE_INGRESS_FILTER,
                    priority: 100,
                    cookie: cookie,
                    match: { eth_type: ETH_TYPE_ARP },
                    goto_table: TABLE_INTERFACE_VIF)
      ]

      @dp_info.add_flows(flows)
    end

    def catch_new_connection(interface, mac_info, ipv4_info)
      cookie = interface.id | (COOKIE_PREFIX_SECURITY_GROUP << COOKIE_PREFIX_SHIFT)
      flows = [
        flow_create(:default,
                    table: TABLE_VIF_PORTS,
                    priority: 20,
                    match: {
                      eth_src: mac_info[:mac_address],
                      eth_type: ETH_TYPE_IPV4,
                      ip_proto: IPV4_PROTOCOL_TCP
                    },
                    match_metadata: { interface: interface.id },
                    cookie: cookie,
                    actions: { output: Controller::OFPP_CONTROLLER }),
        flow_create(:default,
                    table: TABLE_VIF_PORTS,
                    priority: 20,
                    match: {
                      eth_src: mac_info[:mac_address],
                      eth_type: ETH_TYPE_IPV4,
                      ip_proto: IPV4_PROTOCOL_UDP
                    },
                    match_metadata: { interface: interface.id },
                    cookie: cookie,
                    actions: { output: Controller::OFPP_CONTROLLER }),
      ]

      @dp_info.add_flows(flows)
    end

    private
    def open_connection(message)
      debug "opening new connection"
      interface_id = message.cookie & COOKIE_ID_MASK
      interface = MW::Interface.batch[interface_id].commit

      #TODO: Write this as a single query despite model wrappers
      ip_addrs = MW::IpAddress.batch.filter(:ipv4_address => message.ipv4_src.to_i).all.commit
      ip_lease = MW::IpLease.batch.filter(
        :ip_address_id => ip_addrs.map {|ip| ip.id},
        :interface_id => interface_id).all.commit.first
      ip_addr = ip_addrs.find {|i| i.id == ip_lease.ip_address_id }
      network = MW::Network.batch[ip_addr.network_id].commit


      cookie = interface.id | (COOKIE_PREFIX_SECURITY_GROUP << COOKIE_PREFIX_SHIFT)

      match_egress, match_ingress = if message.tcp?
        [
          {
            ip_proto: IPV4_PROTOCOL_TCP,
            tcp_src:  message.tcp_src,
            tcp_dst:  message.tcp_dst
          },
          {
            ip_proto: IPV4_PROTOCOL_TCP,
            tcp_src:  message.tcp_dst,
            tcp_dst:  message.tcp_src
          }
        ]
      elsif message.udp?
        [
          {
            ip_proto: IPV4_PROTOCOL_UDP,
            udp_src:  message.udp_src,
            udp_dst:  message.udp_dst
          },
          {
            ip_proto: IPV4_PROTOCOL_UDP,
            udp_src:  message.udp_dst,
            udp_dst:  message.udp_src
          }
        ]
      end

      flows = if message.tcp? || message.udp?
        [
          flow_create(:default,
                      table: TABLE_VIF_PORTS,
                      priority: 21,
                      match: {
                        dl_src:   message.packet_info.eth_src,
                        eth_type: message.eth_type,
                        ipv4_src: message.ipv4_src,
                        ipv4_dst: message.ipv4_dst,
                      }.merge(match_egress),
                      match_metadata: { interface: interface.id },
                      write_metadata: { network: network.id },
                      # cookie: interface.cookie_for_ip_lease(ip_lease.id),
                      cookie: cookie,
                      goto_table: TABLE_NETWORK_SRC_CLASSIFIER),
          flow_create(:default,
                      table: TABLE_INTERFACE_INGRESS_FILTER,
                      priority: 10,
                      cookie: cookie,
                      match: {
                        dl_dst:   message.packet_info.eth_src,
                        eth_type: ETH_TYPE_IPV4,
                        ipv4_src:   message.ipv4_dst,
                        ipv4_dst:   message.ipv4_src,
                      }.merge(match_ingress),
                      match_metadata: { interface: interface.id },
                      goto_table: TABLE_INTERFACE_VIF)
        ]
      else
        []
      end

      @dp_info.add_flows(flows)
      @dp_info.send_packet_out(message, OFPP_TABLE)
    end

    def apply_rules(message)
      interface_id = message.cookie & COOKIE_ID_MASK
      interface = MW::Interface.batch[interface_id].commit

      groups = interface.batch.security_groups.commit.map { |g|
        Vnet::Openflow::SecurityGroups::SecurityGroup.new(g)
      }

      flows = groups.map { |g| g.install(interface) }.flatten

      @dp_info.add_flows(flows)
      @dp_info.send_packet_out(message, OFPP_TABLE)
    end
  end
end
