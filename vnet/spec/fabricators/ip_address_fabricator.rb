# -*- coding: utf-8 -*-

require 'ipaddress'

Fabricator(:ip_address, class_name: Vnet::Models::IpAddress) do
  network { Fabricate(:network) }
  ipv4_address { sequence(:ipv4_address, IPAddress::IPv4.new("192.168.1.1").to_i) }
end

Fabricator(:ip_address_1, class_name: Vnet::Models::IpAddress) do
  ipv4_address 1
end

Fabricator(:ip_address_2, class_name: Vnet::Models::IpAddress) do
  ipv4_address 2
end
