# -*- coding: utf-8 -*-

module Vnet::Models
  class MacAddress < Base
    taggable 'mac'

    one_to_one :mac_lease
  end
end
