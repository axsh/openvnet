# -*- coding: utf-8 -*-

module Vnet::Models
  class IpRangesRange < Base

    many_to_one :ip_range

    plugin :paranoia
  end
end
