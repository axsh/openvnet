# -*- coding: utf-8 -*-

module Vnet::Models
  class IpAddress < Base
    taggable 'ip'
    many_to_one :network
    one_to_one :ip_lease
  end
end
