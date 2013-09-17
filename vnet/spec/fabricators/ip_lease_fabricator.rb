# -*- coding: utf-8 -*-
Fabricator(:ip_lease, class_name: Vnet::Models::IpLease) do
  network { Fabricate(:network) }
  vif { Fabricate(:interface) }
  ip_address { Fabricate(:ip_address) }
end
