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

  end

end
