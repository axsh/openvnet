# -*- coding: utf-8 -*-

module Vnet::Models

  class MacRangeGroup < Base
    taggable 'mrg'

    plugin :paranoia_is_deleted

    one_to_many :lease_policy_base_networks
    one_to_many :mac_ranges

    plugin :association_dependencies,
    # 0005_mac_leases
    mac_ranges: :destroy

    # TODO: Randomly distribute the lease attempts.
    def address_random
      mac_ranges.each { |mac_range|
        result = mac_range.address_random
        return result if result
      }
      nil
    end

    def lease_random(interface_id)
      mac_ranges.each { |mac_range|
        result = mac_range.lease_random(interface_id)
        return result if result
      }
      nil
    end

  end

end
