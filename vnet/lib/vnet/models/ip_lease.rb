# -*- coding: utf-8 -*-

module Vnet::Models
  class IpLease < Base
    taggable 'il'

    plugin :ip_address

    many_to_one :interface

    dataset_module do
      def join_interfaces
        self.join_table(:inner, :interfaces, :interfaces__id => :ip_leases__interface_id)
      end
    end

    def to_hash
      super.merge({
        ipv4_address: self.ipv4_address
      })
    end
  end
end
