# -*- coding: utf-8 -*-

module Vnet::Models
  class LeasePolicy < Base
    taggable 'lp'

    many_to_many :networks, :join_table => :lease_policy_base_networks
    one_to_many :lease_policy_base_networks

    plugin :paranoia

  end
end
