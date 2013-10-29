# -*- coding: utf-8 -*-

module Vnet::Openflow
  class SecurityGroupManager < Manager
    include Vnet::Openflow::FlowHelpers

    COOKIE_TAG_RULE     = 0x1
    COOKIE_TAG_CONTRACK = 0x2

    Connections = Vnet::Openflow::SecurityGroups::Connections

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

      flows = [IPV4_PROTOCOL_TCP, IPV4_PROTOCOL_UDP].map { |protocol|
        flow_create(:default,
                    table: TABLE_VIF_PORTS,
                    priority: 20,
                    match: {
                      eth_src: mac_info[:mac_address],
                      eth_type: ETH_TYPE_IPV4,
                      ip_proto: protocol
                    },
                    match_metadata: { interface: interface.id },
                    cookie: cookie,
                    actions: { output: Controller::OFPP_CONTROLLER })
      }

      @dp_info.add_flows(flows)
    end

    private
    def open_connection(message)
      debug "opening new connection"

      flows = if message.tcp?
        Connections::TCP.new.open(interface, message)
      elsif message.udp?
        Connections::UDP.new.open(interface, message)
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
