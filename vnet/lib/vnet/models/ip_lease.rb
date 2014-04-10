# -*- coding: utf-8 -*-

module Vnet::Models
  class IpLease < Base
    taggable 'il'

    many_to_one :network

    plugin :paranoia
    plugin :ip_address

    dataset_module do
      def join_interfaces
        self.join_table(:inner, :interfaces, interfaces__id: :ip_leases__interface_id)
      end

      def join_ip_addresses
        self.join(:ip_addresses, ip_addresses__id: :ip_leases__ip_address_id)
      end
    end

    # TODO: Is this really safe if interface_id is changed?
    def cookie_id
      self.class.with_deleted.where(interface_id: self.interface_id).where("id <= #{self.id}").count
    end

    def to_hash
      super.merge({
        ipv4_address: self.ipv4_address
      })
    end
  end
end
