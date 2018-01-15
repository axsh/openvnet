# -*- coding: utf-8 -*-

module Vnet::Models
  class MacAddress < Base
    taggable 'mac'

    plugin :paranoia_is_deleted

    many_to_one :segment
    one_to_one :mac_lease

  end
end
