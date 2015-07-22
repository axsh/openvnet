# -*- coding: utf-8 -*-
Fabricator(:mac_address, class_name: Vnet::Models::MacAddress) do
  mac_address { MacAddr.new(sequence(:mac_address, 1)) }
end
