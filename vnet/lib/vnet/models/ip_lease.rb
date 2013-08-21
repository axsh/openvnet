# -*- coding: utf-8 -*-

module Vnet::Models
  class IpLease < Base
    taggable 'il'

    many_to_one :network
    many_to_one :ip_address
    many_to_one :iface

    dataset_module do
      def join_ifaces
        self.join_table(:inner, :ifaces, :ifaces__id => :ip_leases__iface_id)
      end

      def with_ipv4
        ds = self.join_table(:inner, :ip_addresses, :ip_leases__ip_address_id => :ip_addresses__id)
        ds = ds.select_all(:ip_addresses, :ip_leases)
      end
    end

  end
end
