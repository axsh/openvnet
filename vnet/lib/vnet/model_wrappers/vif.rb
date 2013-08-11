# -*- coding: utf-8 -*-

module Vnet::ModelWrappers
  class Vif < Base
    include Helpers::IPv4
    include Helpers::MacAddr

    def to_hash
      network = self.batch.network.commit
      owner_datapath = self.batch.owner_datapath.commit
      active_datapath = self.batch.active_datapath.commit

      {
        :uuid => uuid,
        :network_uuid => network && network.uuid,
        :owner_datapath_uuid => owner_datapath && owner_datapath.uuid,
        :active_datapath_uuid => active_datapath && active_datapath.uuid,
        :mac_addr => mac_addr_s,
        :ipv4_address => ipv4_address_s,
        :mode => mode
      }
    end
  end
end
