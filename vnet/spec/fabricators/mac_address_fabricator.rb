# -*- coding: utf-8 -*-

Fabricator(:mac_address, class_name: Vnet::Models::MacAddress) do
  id { id_sequence(:mac_address_ids) }

  mac_address { MacAddr.new(id_sequence(:mac_address)) }
end

Fabricator(:mac_address_no_seg, class_name: Vnet::Models::MacAddress) do
  id { id_sequence(:mac_address_ids) }

  mac_address { MacAddr.new(id_sequence(:mac_address)) }
end
