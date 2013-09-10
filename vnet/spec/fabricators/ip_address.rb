# -*- coding: utf-8 -*-
Fabricator(:ip_address, class_name: Vnet::Models::IpAddress) do
  ipv4_address { sequence(:ipv4_address, IPAddress::IPv4.new("192.168.1.1").to_i) }
end
