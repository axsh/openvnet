# -*- coding: utf-8 -*-

module Vnet::Models

  class TranslationStaticAddress < Base
    plugin :paranoia_is_deleted

    many_to_one :translation
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
      Pio::IPv4Address.new(ipv4).to_s
    end

  end

end
