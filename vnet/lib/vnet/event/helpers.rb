# -*- coding: utf-8 -*-

module Vnet::Event::Helpers
  def dispatch_leased_mac_address(mac_lease)
    dispatch_event(LEASED_MAC_ADDRESS,
      id: mac_lease.interface_id,
      mac_lease_id: mac_lease.id,
      mac_address: mac_lease.mac_address,
      contrack_enabled: !self.interface.security_groups_dataset.empty?
    )
  end
end
