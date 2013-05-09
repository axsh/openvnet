# -*- coding: utf-8 -*-

module Vnmgr::Models
  W = Vnmgr::ModelWrappers::NetworkWrapper
  class Network < Base
    taggable 'nw'

    def to_wrapper
      w = W.new

      w.uuid = self.canonical_uuid
      [:display_name,:ipv4_network,:ipv4_prefix,:domain_name,:network_mode,:editable,:created_at,:updated_at].each {|attr|
        w.send("#{attr}=",self.send(attr))
      }
      # w.dc_network_uuid = self.dc_network.canonical_uuid

      w
    end

    def to_hash
      {
        :uuid => self.canonical_uuid,
        :display_name => self.display_name,
        :ipv4_network => self.ipv4_network,
        :ipv4_prefix => self.ipv4_prefix,
        :domain_name => self.domain_name,
        :dc_network_uuid => self.dc_network || self.dc_network.canonical_uuid,
        :network_mode => self.network_mode,
        :editable => self.editable,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
