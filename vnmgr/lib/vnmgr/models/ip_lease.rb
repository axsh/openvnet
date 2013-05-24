# -*- coding: utf-8 -*-

module Vnmgr::Models
  class IpLease < Base
    taggable 'il'

    many_to_one :network
    one_to_one :ip_addresse
    one_to_one :vif
  end
end
