# -*- coding: utf-8 -*-

module Vnet::Models
  class IpAddress < Base
    many_to_one :network
    one_to_one :ip_lease
    one_to_one :datapath
  end
end
