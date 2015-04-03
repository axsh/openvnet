# -*- coding: utf-8 -*-

module Vnet::Models

  # TODO: Refactor.

  class TranslationStaticAddress < Base

    many_to_one :translation
    # TODO: Association needed:
    many_to_one :route_link

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
