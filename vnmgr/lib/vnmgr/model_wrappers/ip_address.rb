# -*- coding: utf-8 -*-

module Vnmgr::ModelWrappers
  class IpAddress < Base
    def to_hash
      {
        :uuid => self.uuid,
        :ipv4_address => self.ipv4_address,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
