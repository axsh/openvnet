# -*- coding: utf-8 -*-
require 'ipaddr'
Fabricator(:route_link, class_name: Vnet::Models::RouteLink) do
  _mac_address { Fabricate(:mac_address) }
end
