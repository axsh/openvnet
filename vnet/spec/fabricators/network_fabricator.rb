# -*- coding: utf-8 -*-

require 'ipaddr'

Fabricator(:network, class_name: Vnet::Models::Network) do
  display_name "network"
  ipv4_network { sequence(:ipv4_network, Pio::IPv4Address.new("192.168.1.1").to_i) }
  ipv4_prefix 24
  domain_name "example.com"
end

Fabricator(:network_for_range, class_name: Vnet::Models::Network) do
  # I'm stressed for time here. ;_;
  display_name "temporary thing for the dc networks fabricator..."
  ipv4_network Pio::IPv4Address.new("10.102.0.1").to_i
  ipv4_prefix 24
  domain_name "example.com"
  mode 'virtual'
end

Fabricator(:pnet_public1, class_name: Vnet::Models::Network) do
  uuid "nw-public1"
  display_name "public1"
  ipv4_network Pio::IPv4Address.new("192.168.1.0").to_i
  ipv4_prefix 24
  domain_name "example.com"
  mode 'physical'
end

Fabricator(:pnet_public2, class_name: Vnet::Models::Network) do
  uuid "nw-public2"
  display_name "public2"
  ipv4_network Pio::IPv4Address.new("192.168.2.0").to_i
  ipv4_prefix 24
  domain_name "example.com"
  mode 'physical'
end

Fabricator(:vnet_1, class_name: Vnet::Models::Network) do
  uuid "nw-aaaaaaaa"
  display_name "vnet1"
  ipv4_network Pio::IPv4Address.new("10.102.0.0").to_i
  ipv4_prefix 24
  domain_name "example.com"
  mode 'virtual'
end

Fabricator(:vnet_2, class_name: Vnet::Models::Network) do
  uuid "nw-bbbbbbbb"
  display_name "vnet2"
  ipv4_network Pio::IPv4Address.new("10.102.1.0").to_i
  ipv4_prefix 24
  domain_name "example.vnet2.com"
  mode 'virtual'
end

Fabricator(:network_with_prefix_30, class_name: Vnet::Models::Network) do
  ipv4_network Pio::IPv4Address.new("10.102.0.100").to_i
  ipv4_prefix 30
  mode 'virtual'
end
