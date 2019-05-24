# -*- coding: utf-8 -*-

module Vnet::Models
  class DnsService < Base
    taggable "dnss"

    plugin :paranoia_is_deleted

    many_to_one :network_service
    one_to_many :dns_records

    plugin :association_dependencies,
    # 0001_origin
    dns_records: :destroy

    def before_validation
      self.public_dns.gsub!(/\s/, "") if self.public_dns
      super
    end

    def validate
      validates_presence :network_service_id

      if network_service && network_service.mode != "dns"
        errors.add(:network_service, 'must be dns')
      end

      has_invalid = public_dns && public_dns.split(",").detect { |ip_address|
        begin
          IPAddr.new(ip_address, Socket::AF_INET)
          false
        rescue IPAddr::InvalidAddressError
          true
        end
      }

      errors.add(:public_dns, 'is not valid') if has_invalid
    end

  end
end
