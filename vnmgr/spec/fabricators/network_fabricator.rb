require 'ipaddr'
Fabricator(:network, class_name: Vnmgr::Models::Network) do
  display_name "network"
  ipv4_network IPAddr.new("192.168.1.1").to_i
  ipv4_prefix 24
  domain_name Faker::Internet.domain_name
  dc_network
  #network_mode
  #editable true
end
