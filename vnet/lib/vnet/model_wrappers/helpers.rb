# -*- coding: utf-8 -*-

module Vnet::ModelWrappers::Helpers
  module IPv4
    def ipv4_address_s
      self.ipv4_address && parse_ipv4(self.ipv4_address)
    end

    def ipv4_network_s
      self.ipv4_network && parse_ipv4(self.ipv4_network)
    end

    private
    def parse_ipv4(ipv4)
      IPAddress::IPv4::parse_u32(ipv4).to_s
    end
  end

  module MacAddr
    def mac_address_s(delim = ":")
      self.mac_address && (
        mac = self.mac_address.to_s(16)
        while mac.length < 12
          mac.insert(0,'0')
        end
        mac.scan(/.{2}|.+/).join(delim)
      )
    end
  end
end
