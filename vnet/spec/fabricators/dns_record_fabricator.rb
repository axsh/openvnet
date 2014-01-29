# -*- coding: utf-8 -*-
Fabricator(:dns_record, class_name: Vnet::Models::DnsRecord) do
  name "foo"
  ipv4_address IPAddr.new("192.168.1.10")
end
