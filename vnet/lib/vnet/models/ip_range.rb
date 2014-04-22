# -*- coding: utf-8 -*-

module Vnet::Models
  class IpRange < Base
    taggable 'ipr'

    one_to_many :lease_policy_base_networks
    one_to_many :ip_ranges_ranges

    plugin :paranoia
  end
end
