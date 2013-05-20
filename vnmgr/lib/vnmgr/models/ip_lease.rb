# -*- coding: utf-8 -*-

module Vnmgr::Models
  class IpLease < Base
    taggable 'il'

    many_to_one :Network
    one_to_one :IpAddress
    one_to_one :Vif
  end
end
