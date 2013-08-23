# -*- coding: utf-8 -*-

module Vnet::ModelWrappers
  class Interface < Base

    def to_hash
      {
        :uuid => self.uuid,
        :network_id => self.network_id,
        :name => self.name,
        :mode => self.mode,
        :active_datapath_id => self.active_datapath_id,
        :owner_datapath_id => self.owner_datapath_id,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
