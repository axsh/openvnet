# -*- coding: utf-8 -*-

module Vnet::ModelWrappers::Helpers
  module IPv4
    def ipv4_address_s
      self.ip_address && IPAddress::IPv4::parse_u32(self.ip_address.ipv4_address).to_s
    end
  end

  module MacAddr
    def mac_address_s(delim = ":")
      mac_address && (
        mac = mac_address.to_s(16)
        while mac.length < 12
          mac.insert(0,'0')
        end
        mac.scan(/.{2}|.+/).join(delim)
      )
    end
  end
end
