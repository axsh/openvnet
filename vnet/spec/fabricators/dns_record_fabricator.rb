# -*- coding: utf-8 -*-
Fabricator(:dns_record, class_name: Vnet::Models::DnsRecord) do
  name "foo"
  ipv4_address Pio::IPv4Address.new("192.168.1.10")
end
