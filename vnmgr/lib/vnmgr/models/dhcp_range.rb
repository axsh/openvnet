# -*- coding: utf-8 -*-

module Vnmgr::Models
  class DhcpRange < Base
    taggable 'dr'
    many_to_one :Network
  end
end
