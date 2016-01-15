# -*- coding: utf-8 -*-
Fabricator(:network_service, class_name: Vnet::Models::NetworkService) do
  mode 'dhcp'
end

Fabricator(:network_service_dhcp, class_name: Vnet::Models::NetworkService) do
  mode 'dhcp'
end

Fabricator(:network_service_dns, class_name: Vnet::Models::NetworkService) do
  mode 'dns'
end
