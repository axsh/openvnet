# -*- coding: utf-8 -*-
Fabricator(:interface, class_name: Vnet::Models::Interface) do
end

Fabricator(:interface_dp1eth0, class_name: Vnet::Models::Interface) do
  uuid 'if-dp1eth0'
  display_name "test-dp1eth0"
  port_name "eth0"
  mode "host"
end

Fabricator(:interface_dp2eth0, class_name: Vnet::Models::Interface) do
  uuid 'if-dp2eth0'
  display_name "test-dp2eth0"
  port_name "eth0"
  mode "host"
end

Fabricator(:interface_dp3eth0, class_name: Vnet::Models::Interface) do
  uuid 'if-dp3eth0'
  display_name "test-dp3eth0"
  port_name "eth0"
  mode "host"
end
