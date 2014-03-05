# -*- coding: utf-8 -*-

module Vnet::Event::Helpers
  def dispatch_update_sg_ip_addresses(security_group)
    dispatch_event(Vnet::Event::UPDATED_SG_IP_ADDRESSES,
      id: security_group.id,
      ip_addresses: security_group.ip_addresses
    )
  end
end
