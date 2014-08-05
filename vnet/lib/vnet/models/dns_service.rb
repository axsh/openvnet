# -*- coding: utf-8 -*-

require 'ipaddr'

module Vnet::Models

  class DnsService < Base
    taggable "dnss"

    plugin :paranoia_is_deleted

    many_to_one :network_service
    one_to_many :dns_records

    plugin :association_dependencies,
      :dns_records => :destroy

    def before_validation
      self.public_dns.gsub!(/\s/, "") if self.public_dns
    end

    def validate
      validates_presence :network_service_id

      if network_service && network_service.type != "dns"
        errors.add(:network_service, 'must be dns')
      end

      has_invalid = public_dns && public_dns.split(",").detect { |ip_address|
        !IPAddr.new(ip_address).ipv4?
      }

      errors.add(:public_dns, 'is not valid') if has_invalid
    end

  end

end
