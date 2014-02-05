# -*- coding: utf-8 -*-
module Vnet::NodeApi
  class InterfaceSecurityGroup < Base
    class << self
      #TODO: Dispatch events for vnics leaving and join secgs
      def create(options)
        ifsecg = super(options)
        group = ifsecg.security_group

        #TODO: Only dispatch this event if this interface has filtering enabled
        # dispatch_event(ADDED_INTERFACE_TO_SG,
        #   id: group.id,
        #   uuid: group.canonical_uuid,
        #   interface_id: ifsecg.interface_id,
        #   interface_cookie_id: group.interface_cookie_id(ifsecg.interface_id)
        # )
        dispatch_update_isolation group
      end

      def destroy(id)
        ifsecg = super(id)

        dispatch_update_isolation ifsecg.security_group
      end

      def dispatch_update_isolation(group)
        dispatch_event(UPDATED_SG_ISOLATION,
          id: group.id,
          uuid: group.canonical_uuid,
          ip_addresses: group.ip_addresses
        )
      end
    end
  end
end
