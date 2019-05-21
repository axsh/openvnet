# -*- coding: utf-8 -*-

require 'ipaddr'

Fabricator(:route, class_name: Vnet::Models::Route) do
  id { id_sequence(:route_ids) }
  interface { Fabricate(:interface) }
  route_link { Fabricate(:route_link) }
  ipv4_network Pio::IPv4Address.new("192.168.2.0").to_i
  ipv4_prefix 24
end

Fabricator(:route_free, class_name: Vnet::Models::Route) do
  id { id_sequence(:route_ids) }
  ipv4_network Pio::IPv4Address.new("192.168.2.0").to_i
  ipv4_prefix 24
end
