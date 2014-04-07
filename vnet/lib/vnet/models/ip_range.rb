# -*- coding: utf-8 -*-

module Vnet::Models
  class IpRange < Base
    taggable 'ipr'

    plugin :paranoia
  end
end
