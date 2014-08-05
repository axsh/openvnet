# -*- coding: utf-8 -*-

module Vnet::Models

  # TODO: Refactor.
  class MacAddress < Base
    taggable 'mac'

    one_to_one :mac_lease
    one_to_one :route_link

    one_to_many :ip_leases do |ds|
      ds.mac_lease.ip_leases
    end

  end
end
