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
