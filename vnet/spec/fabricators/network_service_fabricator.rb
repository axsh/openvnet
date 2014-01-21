# -*- coding: utf-8 -*-
Fabricator(:network_service, class_name: Vnet::Models::NetworkService) do
end

Fabricator(:network_service_dhcp, class_name: Vnet::Models::NetworkService) do
  type "dhcp"
end

Fabricator(:network_service_dns, class_name: Vnet::Models::NetworkService) do
  type "dns"
end
