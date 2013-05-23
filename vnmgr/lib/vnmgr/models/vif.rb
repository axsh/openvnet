# -*- coding: utf-8 -*-

module Vnmgr::Models
  class Vif < Base
    taggable 'vif'
    many_to_one :network
    many_to_one :NetworkService

    one_to_one :IpLease
  end
end
