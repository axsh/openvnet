# -*- coding: utf-8 -*-
Fabricator(:mac_address, class_name: Vnet::Models::MacAddress) do
  mac_address { sequence(:mac_address, 0) }
end
