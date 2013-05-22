# -*- coding: utf-8 -*-

module Vnmgr::Models
  class Vif < Base
    taggable 'vif'
    many_to_one :network
    many_to_one :network_service

    one_to_one :ip_lease
  end
end
