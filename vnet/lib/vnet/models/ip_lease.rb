# -*- coding: utf-8 -*-

module Vnet::Models
  class IpLease < Base
    taggable 'il'

    many_to_one :network
    many_to_one :ip_address
    many_to_one :interface

    plugin :association_dependencies, ip_address: :destroy

    dataset_module do
      def join_vifs
        self.join_table(:inner, :interfaces, :interfaces__id => :ip_leases__interface_id)
      end

      def with_ipv4
        ds = self.join_table(:inner, :ip_addresses, :ip_leases__ip_address_id => :ip_addresses__id)
        ds = ds.select_all(:ip_addresses, :ip_leases)
      end
    end

    def ipv4_address
      self.ip_address.try(:ipv4_address)
    end

    def to_hash
      super.merge({
        ipv4_address: self.ipv4_address
      })
    end
  end
end
