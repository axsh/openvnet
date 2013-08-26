# -*- coding: utf-8 -*-
Fabricator(:mac_address, class_name: Vnet::Models::MacAddress) do
  uuid 'mac-testaddr'
  mac_address 1
end
