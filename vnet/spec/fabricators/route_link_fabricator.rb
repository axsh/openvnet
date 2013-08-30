# -*- coding: utf-8 -*-
require 'ipaddr'
Fabricator(:route_link, class_name: Vnet::Models::RouteLink) do
  mac_address Random.rand(0..0xffffffffffff)
end
