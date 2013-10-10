# -*- coding: utf-8 -*-

module Vnet::Models
  class IpLease < Base
    taggable 'il'

    plugin :ip_address

    dataset_module do
      def join_interfaces
        self.join_table(:inner, :interfaces, interfaces__id: :ip_leases__interface_id)
      end

      def join_ip_addresses
        self.join(:ip_addresses, ip_addresses__id: :ip_leases__ip_address_id)
      end
    end

    def to_hash
      super.merge({
        ipv4_address: self.ipv4_address
      })
    end
  end
end
