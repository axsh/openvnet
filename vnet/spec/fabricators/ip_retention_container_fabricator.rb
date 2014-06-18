Fabricator(:ip_retention_container, class_name: Vnet::Models::IpRetentionContainer) do
  lease_time 3600
  grace_time 1800
end
