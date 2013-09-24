# -*- coding: utf-8 -*-

module Vnet::ModelWrappers
  class Interface < Base

    def mac_address
      self.batch.mac_address.commit
    end

    def to_hash
      network = self.batch.network.commit
      owner_datapath = self.batch.owner_datapath.commit
      active_datapath = self.batch.active_datapath.commit

      {
        :uuid => uuid,
        :network_uuid => network && network.uuid,
        :owner_datapath_uuid => owner_datapath && owner_datapath.uuid,
        :active_datapath_uuid => active_datapath && active_datapath.uuid,
        :mode => mode
      }
    end
  end
end
