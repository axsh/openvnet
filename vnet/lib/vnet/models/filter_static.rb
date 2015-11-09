# -*- coding: utf-8 -*-

module Vnet::Models

  # TODO: Refactor.

  class FilterStatic < Base

    many_to_one :filter
    # TODO: Association needed:

    def ipv4_src_address_s
      self.ipv4_src_address && parse_ipv4(self.ipv4_src_address)
    end

    def ipv4_dst_address_s
      self.ipv4_dst_address && parse_ipv4(self.ipv4_dst_address)
    end

    private

    def parse_ipv4(ipv4)
      IPAddress::IPv4::parse_u32(ipv4).to_s
    end

    def validate
      super
    end
   
  end

end
