# -*- coding: utf-8 -*-
require 'ipaddr'
Fabricator(:network, class_name: Vnet::Models::Network) do
  display_name "network"
  ipv4_network IPAddr.new("192.168.1.1").to_i
  ipv4_prefix 24
  domain_name "example.com"
  dc_network
  #network_mode
  #editable true
end

Fabricator(:vnet_1, class_name: Vnet::Models::Network) do
  uuid "nw-aaaaaaaa"
  display_name "vnet1"
  ipv4_network IPAddr.new("10.102.0.1").to_i
  ipv4_prefix 24
  domain_name "example.com"
  dc_network
  network_mode 'virtual'
  #editable true
end
