# -*- coding: utf-8 -*-
require 'ipaddr'
Fabricator(:route, class_name: Vnet::Models::Route) do
  uuid
  vif_id 1
  route_link_id 1
  ipv4_address IPAddr.new("192.168.2.0").to_i
  ipv4_prefix 24
end
