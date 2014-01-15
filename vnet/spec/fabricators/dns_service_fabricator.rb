# -*- coding: utf-8 -*-
Fabricator(:dns_service, class_name: Vnet::Models::DnsService) do
  network_service { Fabricate(:network_service, type: "dns") }
  public_dns "8.8.8.8,8.8.4.4"
end
