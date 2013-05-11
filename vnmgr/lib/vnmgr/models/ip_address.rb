# -*- coding: utf-8 -*-

module Vnmgr::Models
  class IpAddress < Base
    taggable 'ia'
    many_to_one :Network
    one_to_one :IpLease
  end
end
