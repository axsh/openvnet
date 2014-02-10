# -*- coding: utf-8 -*-
module Vnet::NodeApi
  class InterfaceSecurityGroup < Base
    class << self
      def create(options)
        ifsecg = super(options)
        group = ifsecg.security_group

        #TODO: Only dispatch this event if this interface has filtering enabled
        dispatch_event(ADDED_INTERFACE_TO_SG,
          id: group.id,
          interface_id: ifsecg.interface_id,
          interface_cookie_id: group.interface_cookie_id(ifsecg.interface_id)
        )
        dispatch_update_isolation group
      end

      def destroy(id)
        ifsecg = super(id)
        group = ifsecg.security_group

        dispatch_event(REMOVED_INTERFACE_FROM_SG,
          id: group.id,
          interface_id: ifsecg.interface_id
        )

        dispatch_update_isolation group
      end

      private
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
