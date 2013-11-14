# -*- coding: utf-8 -*-

module Vnet::Openflow
  class SecurityGroupManager < Manager
    include Vnet::Openflow::FlowHelpers

    COOKIE_SG_TYPE_MASK = 0xf << COOKIE_TAG_SHIFT

    COOKIE_SG_TYPE_TAG  = 0x1 << COOKIE_TAG_SHIFT
    COOKIE_SG_TYPE_RULE = 0x2 << COOKIE_TAG_SHIFT

    COOKIE_TYPE_VALUE_SHIFT = 36
    COOKIE_TYPE_VALUE_MASK  = 0xfffff << COOKIE_TYPE_VALUE_SHIFT

    COOKIE_TAG_INGRESS_ARP_ACCEPT = 0x1 << COOKIE_TYPE_VALUE_SHIFT
    COOKIE_TAG_INGRESS_CATCH      = 0x2 << COOKIE_TYPE_VALUE_SHIFT
    COOKIE_TAG_INGRESS_ACCEPT_ALL = 0x3 << COOKIE_TYPE_VALUE_SHIFT

    def initialize(*args)
      super(*args)

      accept_ingress_arp
    end

    def packet_in(message)
      apply_rules(message)
    end

    def catch_ingress_packet(interface)
      flows = [
        flow_create(:default,
                    table: TABLE_INTERFACE_INGRESS_FILTER,
                    priority: 1,
                    match_metadata: { interface: interface.id },
                    cookie: catch_ingress_cookie(interface),
                    actions: { output: Controller::OFPP_CONTROLLER }),
      ]

      @dp_info.add_flows(flows)
    end

    def remove_catch_ingress(interface)
      @dp_info.del_cookie catch_ingress_cookie(interface)
    end

    def remove_rules(interface)
      interface = MW::Interface.batch[interface.id].commit

      groups = interface.batch.security_groups.commit.map { |g|
        Vnet::Openflow::SecurityGroups::SecurityGroup.new(g, interface.id)
      }

      groups.each { |g|
        debug "'#{interface.uuid}' removing rules for group '#{g.uuid}'"
        @dp_info.del_cookie(g.cookie)
      }
    end

    private
    def catch_ingress_cookie(interface)
      interface.id |
        COOKIE_TYPE_SECURITY_GROUP |
        COOKIE_SG_TYPE_TAG |
        COOKIE_TAG_INGRESS_CATCH
    end

    def accept_ingress_arp
      cookie = COOKIE_TYPE_SECURITY_GROUP |
        COOKIE_SG_TYPE_TAG |
        COOKIE_TAG_INGRESS_ARP_ACCEPT

      @dp_info.add_flows [
        flow_create(:default,
                    table: TABLE_INTERFACE_INGRESS_FILTER,
                    priority: 100,
                    cookie: cookie,
                    match: { eth_type: ETH_TYPE_ARP },
                    goto_table: TABLE_INTERFACE_VIF)
      ]
    end

    def apply_rules(message)
      interface_id = message.cookie & COOKIE_ID_MASK
      interface = MW::Interface.batch[interface_id].commit

      groups = interface.batch.security_groups.commit.map { |g|
        Vnet::Openflow::SecurityGroups::SecurityGroup.new(g, interface_id)
      }

      flows = if groups.empty?
        # Accept all traffic if this interface isn't in any security groups
        # This behaviour will change in the future
        cookie = interface_id |
          COOKIE_TYPE_SECURITY_GROUP |
          COOKIE_SG_TYPE_TAG |
          COOKIE_TAG_INGRESS_ACCEPT_ALL

        [
          flow_create(:default,
            table: TABLE_INTERFACE_INGRESS_FILTER,
            priority: Vnet::Openflow::SecurityGroups::RULE_PRIORITY,
            idle_timeout: Vnet::Openflow::SecurityGroups::IDLE_TIMEOUT,
            cookie: cookie,
            match_metadata: { interface: interface_id },
            goto_table: TABLE_INTERFACE_VIF)
        ]
      else
        groups.map { |g| g.install(interface) }.flatten
      end

      @dp_info.add_flows(flows)
      @dp_info.send_packet_out(message, OFPP_TABLE)
    end
  end
end
