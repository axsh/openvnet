# -*- coding: utf-8 -*-
require 'ipaddr'
Fabricator(:route_link, class_name: Vnet::Models::RouteLink) do
  mac_address { sequence(:mac_address, 100) }
end
