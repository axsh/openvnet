# -*- coding: utf-8 -*-

module Vnet::Openflow
  class SecurityGroupManager < Manager

    def packet_in(message)
      interface_id = message.cookie & COOKIE_ID_MASK
      interface = MW::Interface.batch[interface_id].commit

      groups = interface.batch.security_groups.commit.map { |g|
        Vnet::Openflow::SecurityGroups::SecurityGroup.new(g)
      }

      flows = groups.map { |g| g.install(interface) }.flatten

      @dp_info.add_flows(flows)
      @dp_info.send_packet_out(message, OFPP_TABLE)
    end

    def insert_catch_flow(interface)
      cookie = interface.id | (COOKIE_PREFIX_SECURITY_GROUP << COOKIE_PREFIX_SHIFT)
      flows = [
        interface.flow_create(:default,
                              table: TABLE_INTERFACE_INGRESS_FILTER,
                              priority: 1,
                              match_metadata: { interface: interface.id },
                              cookie: cookie,
                              actions: {
                                output: Controller::OFPP_CONTROLLER
                              }),
        interface.flow_create(:default,
                              table: TABLE_INTERFACE_INGRESS_FILTER,
                              priority: 100,
                              cookie: cookie,
                              match: { eth_type: 0x0806 },
                              goto_table: TABLE_INTERFACE_VIF)
      ]

      @dp_info.add_flows(flows)
    end
  end
end
