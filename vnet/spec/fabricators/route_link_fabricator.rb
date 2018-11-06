# -*- coding: utf-8 -*-

require 'ipaddr'

Fabricator(:route_link, class_name: Vnet::Models::RouteLink) do
  id { id_sequence(:route_link_ids) }

  _mac_address { Fabricate(:mac_address) }
end

Fabricator(:route_link_1, class_name: Vnet::Models::RouteLink) do
  id { id_sequence(:route_link_ids) }
  uuid "rl-aaaaaaaa"

  _mac_address { Fabricate(:mac_address) }
end

Fabricator(:route_link_2, class_name: Vnet::Models::RouteLink) do
  id { id_sequence(:route_link_ids) }
  uuid "rl-bbbbbbbb"

  _mac_address { Fabricate(:mac_address) }
end
