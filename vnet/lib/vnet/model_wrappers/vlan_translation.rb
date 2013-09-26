# -*- coding: utf-8 -*-

module Vnet::ModelWrappers
  class VlanTranslation < Base
    def to_hash
      {
        :mac_address => self.mac_address,
        :vlan_id => self.vlan_id,
        :network_id => self.network_id
      }
    end
  end
end
