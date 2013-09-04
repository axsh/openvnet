# -*- coding: utf-8 -*-
require 'ipaddress'

module Vnet::ModelWrappers
  class Datapath < Base
    def ipv4_address_s
      self.ipv4_address && IPAddress::IPv4::parse_u32(self.ipv4_address).to_s
    end

    def to_hash
      dc_segment = self.batch.dc_segment.commit
      {
        :uuid => self.uuid,
        :open_flow_controller_uuid => self.open_flow_controller_uuid,
        :display_name => self.display_name,
        :ipv4_address => self.ipv4_address,
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
