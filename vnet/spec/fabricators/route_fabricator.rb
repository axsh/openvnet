# -*- coding: utf-8 -*-
require 'ipaddr'

Fabricator(:route_any, class_name: Vnet::Models::Route) do
end

Fabricator(:route, class_name: Vnet::Models::Route) do
  interface { Fabricate(:interface) }
  route_link { Fabricate(:route_link) }
  ipv4_network IPAddr.new("192.168.2.0").to_i
  ipv4_prefix 24
end
