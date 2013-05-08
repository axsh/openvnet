# -*- coding: utf-8 -*-

module Vnmgr::ModelWrappers
  class NetworkWrapper
    backend_namespace = "network"

    attr_accessor :uuid
    attr_accessor :display_name
    attr_accessor :ipv4_network
    attr_accessor :ipv4_prefix
    attr_accessor :domain_name
    attr_accessor :dc_network_uuid
    attr_accessor :network_mode
    attr_accessor :editable
    attr_accessor :created_at
    attr_accessor :updated_at

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
