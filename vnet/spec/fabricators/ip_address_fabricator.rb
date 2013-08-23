# -*- coding: utf-8 -*-
Fabricator(:ip_address_1, class_name: Vnet::Models::IpAddress) do
  ipv4_address 1
end

Fabricator(:ip_address_2, class_name: Vnet::Models::IpAddress) do
  ipv4_address 2 
end
