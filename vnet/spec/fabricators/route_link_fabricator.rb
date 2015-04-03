# -*- coding: utf-8 -*-

require 'ipaddr'

Fabricator(:route_link, class_name: Vnet::Models::RouteLink) do
  mac_address { sequence(:mac_address, 100) }
end

Fabricator(:route_link_1, class_name: Vnet::Models::RouteLink) do
  uuid "rl-aaaaaaaa"
  mac_address { sequence(:mac_address, 101) }
end

Fabricator(:route_link_2, class_name: Vnet::Models::RouteLink) do
  uuid "rl-bbbbbbbb"
  mac_address { sequence(:mac_address, 102) }
end
