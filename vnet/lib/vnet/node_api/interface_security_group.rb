# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class InterfaceSecurityGroup < Base
    class << self
      include Vnet::Event::Helpers

      def create(options)
        ifsecg = super(options)
        group = ifsecg.security_group
        interface = ifsecg.interface

        dispatch_event(ADDED_INTERFACE_TO_SG,
          id: group.id,
          interface_id: ifsecg.interface_id,
          interface_cookie_id: group.interface_cookie_id(ifsecg.interface_id),
          interface_owner_datapath_id: interface.owner_datapath_id,
          interface_active_datapath_id: interface.active_datapath_id,
        )

        dispatch_update_sg_ip_addresses(group)
      end

      def destroy(id)
        ifsecg = super(id)
        group = ifsecg.security_group

        dispatch_event(REMOVED_INTERFACE_FROM_SG,
          id: group.id,
          interface_id: ifsecg.interface_id,
        )

        dispatch_update_sg_ip_addresses(group)
      end
    end
  end
end
