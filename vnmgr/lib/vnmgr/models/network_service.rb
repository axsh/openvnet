# -*- coding: utf-8 -*-

module Vnmgr::Models
  class NetworkService < Base
    taggable 'ns'
    one_to_one :vif
  end
end
