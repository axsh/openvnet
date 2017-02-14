# -*- coding: utf-8 -*-

Fabricator(:ip_retention, class_name: Vnet::Models::IpRetention) do
  # id { id_sequence(:ip_retention) }
end

Fabricator(:ip_retention_with_ip_lease, class_name: Vnet::Models::IpRetention) do
  # id { id_sequence(:ip_retention) }

  ip_lease { Fabricate(:ip_lease) }
end

Fabricator(:ip_retention_with_container, class_name: Vnet::Models::IpRetention) do
  # id { id_sequence(:ip_retention) }

  ip_retention_container { Fabricate(:ip_retention_container) }
end
