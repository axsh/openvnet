# -*- coding: utf-8 -*-
require "ipaddress"

Fabricator(:dhcp_range, class_name: Vnet::Models::DhcpRange) do
  network { Fabricate(:network_for_range) }
  range_begin { 174456834 }
  range_end { 174456934 }
end
