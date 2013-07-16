# -*- coding: utf-8 -*-

module Vnet::Models
  class DhcpRange < Base
    taggable 'dr'
    many_to_one :network
  end
end
