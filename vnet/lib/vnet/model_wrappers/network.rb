# -*- coding: utf-8 -*-
require 'ipaddress'

module Vnet::ModelWrappers
  class Network < Base
    def ipv4_network_s
      IPAddress::IPv4::parse_u32(self.ipv4_network).to_s
    end
  end
end
