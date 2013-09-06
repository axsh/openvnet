# -*- coding: utf-8 -*-

module Vnet::ModelWrappers
  class Vif < Base
    def to_hash
      network = self.batch.network.commit
      owner_datapath = self.batch.owner_datapath.commit
      active_datapath = self.batch.active_datapath.commit

      {
        :uuid => uuid,
        :network_uuid => network && network.uuid,
        :owner_datapath_uuid => owner_datapath && owner_datapath.uuid,
        :active_datapath_uuid => active_datapath && active_datapath.uuid,
        :ipv4_address => ipv4_address_s,
        :mode => mode
      }
    end

    def ipv4_address_s
      self.ipv4_address && IPAddress::IPv4::parse_u32(self.ipv4_address).to_s
    end

    def mac_addr_s(delim = ":")
      mac_addr.to_s(16).tap { |mac|
        while mac.length < 12
          mac.insert(0,'0')
        end
        mac.scan(/.{2}|.+/).join(delim)
      }
    end
  end
end
