# -*- coding: utf-8 -*-

module Vnet::Models
  class IpRangeGroup < Base
    taggable 'iprg'

    one_to_many :lease_policy_base_networks
    one_to_many :ip_ranges

    plugin :paranoia
  end
end
