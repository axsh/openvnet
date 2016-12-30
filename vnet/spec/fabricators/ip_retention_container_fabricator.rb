# -*- coding: utf-8 -*-

Fabricator(:ip_retention_container, class_name: Vnet::Models::IpRetentionContainer) do
  # id { id_sequence(:ip_retention_container) }

  lease_time 3600
  grace_time 1800
end
