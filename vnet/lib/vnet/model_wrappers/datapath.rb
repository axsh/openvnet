# -*- coding: utf-8 -*-
require 'ipaddress'

module Vnet::ModelWrappers
  class Datapath < Base
    include Helpers::IPv4

    def to_hash
      dc_segment = self.batch.dc_segment.commit
      {
        :uuid => self.uuid,
        :display_name => self.display_name,
        :ipv4_address => self.ipv4_address_s,
        :is_connected => self.is_connected,
        :dpid => self.dpid,
        :dc_segment_uuid => dc_segment && dc_segment.uuid,
        :node_id => self.node_id,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
