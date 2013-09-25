# -*- coding: utf-8 -*-

module Vnet::Models
  class MacAddress < Base
    taggable 'mac'

    one_to_one :mac_lease

    one_to_one :route_link
  end
end
