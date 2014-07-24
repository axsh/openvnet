# -*- coding: utf-8 -*-

require "ipaddress"

module Vnet::Models

  # TODO: Refactor.
  class DnsService < Base
    taggable "dnss"

    plugin :paranoia

    many_to_one :network_service
    one_to_many :dns_records

    plugin :association_dependencies,
      :dns_records => :destroy

    def before_validation
      self.public_dns.gsub!(/\s/, "") if self.public_dns
    end

    def validate
      if public_dns && !public_dns.split(",").all? { |ip| IPAddress.valid_ipv4?(ip) }
        errors.add(:public_dns, 'is not valid')
      end
      validates_presence :network_service_id
      if network_service && network_service.type != "dns"
        errors.add(:network_service, 'must be dns')
      end
    end
  end
end
