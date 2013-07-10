# -*- coding: utf-8 -*-

module Vnmgr::ModelWrappers
  class Route < Base

    def to_hash
      {
        :uuid => self.uuid,
        :ipv4_network => self.ipv4_network,
        :ipv4_prefix => self.ipv4_prefix,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
