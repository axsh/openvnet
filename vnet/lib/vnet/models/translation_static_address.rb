# -*- coding: utf-8 -*-

module Vnet::Models

  class TranslationStaticAddress < Base
    plugin :paranoia_is_deleted

    many_to_one :translation
    many_to_one :route_link

    one_to_one :ingress_network, :class => Network
    one_to_one :egress_network, :class => Network

    def ingress_ipv4_address_s
      self.ingress_ipv4_address && parse_ipv4(self.ingress_ipv4_address)
    end

    def egress_ipv4_address_s
      self.egress_ipv4_address && parse_ipv4(self.egress_ipv4_address)
    end

    #TODO: properly use module for this
    private

    def parse_ipv4(ipv4)
      IPAddress::IPv4::parse_u32(ipv4).to_s
    end

  end

end
