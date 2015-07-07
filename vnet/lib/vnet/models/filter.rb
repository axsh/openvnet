# -*- coding: utf-8 -*-

module Vnet::Models
  class Filter < Base
    taggable 'fil'

    plugin :paranoia_is_deleted

    one_to_many :filter_static

    many_to_one :interface

    plugin :association_dependencies,
    # 0001_origin
    filter_static: :destroy,

    def ipv4_address_s
      self.ipv4_address && parse_ipv4(self.ipv4_address)
    end

    #TODO: properly use module for this
    private

    def parse_ipv4(ipv4)
      IPAddress::IPv4::parse_u32(ipv4).to_s
    end
    
  end
end
