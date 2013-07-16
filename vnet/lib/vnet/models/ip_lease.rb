# -*- coding: utf-8 -*-

module Vnet::Models
  class IpLease < Base
    taggable 'il'

    many_to_one :network
    many_to_one :ip_address
    one_to_one :vif
  end
end
