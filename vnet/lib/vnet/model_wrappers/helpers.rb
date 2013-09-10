# -*- coding: utf-8 -*-

module Vnet::ModelWrappers::Helpers
  module IPv4
    def ipv4_address_s
      self.ipv4_address && IPAddress::IPv4::parse_u32(self.ipv4_address).to_s
    end
  end

  module MacAddr
    def mac_addr_s(delim = ":")
      mac_addr && (
        mac = mac_addr.to_s(16)
        while mac.length < 12
          mac.insert(0,'0')
        end
        mac.scan(/.{2}|.+/).join(delim)
      )
    end
  end
end
