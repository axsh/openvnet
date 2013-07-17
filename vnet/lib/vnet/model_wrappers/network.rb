# -*- coding: utf-8 -*-

module Vnet::ModelWrappers
  class Network < Base

    def network_id
      self.id
    end

    def to_hash
      {
        :uuid => self.uuid,
        :display_name => self.display_name,
        :ipv4_network => self.ipv4_network,
        :ipv4_prefix => self.ipv4_prefix,
        :domain_name => self.domain_name,
        :dc_network_uuid => self.dc_network_uuid,
        :network_mode => self.network_mode,
        :editable => self.editable,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
