# -*- coding: utf-8 -*-
require 'ipaddress'

module Vnet::ModelWrappers
  class Network < Base

    def network_id
      self.id
    end

    def ipv4_network_s
      IPAddress::IPv4::parse_u32(self.ipv4_network).to_s
    end

    def to_hash
      {
        :uuid => self.uuid,
        :display_name => self.display_name,
        :ipv4_network => self.ipv4_network,
        :ipv4_prefix => self.ipv4_prefix,
        :domain_name => self.domain_name,
        :network_mode => self.network_mode,
        :editable => self.editable,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
