# -*- coding: utf-8 -*-

Fabricator(:mac_range, class_name: Vnet::Models::MacRange) do
end

Fabricator(:mac_range_with_range, class_name: Vnet::Models::MacRange) do
  begin_mac_address MacAddr.new("08:00:10:aa:00:00").to_i
  end_mac_address MacAddr.new("08:00:10:aa:ff:ff").to_i
end

Fabricator(:mac_range_with_range2, class_name: Vnet::Models::MacRange) do
  begin_mac_address MacAddr.new("08:00:20:aa:00:00").to_i
  end_mac_address MacAddr.new("08:00:20:aa:ff:ff").to_i
end
