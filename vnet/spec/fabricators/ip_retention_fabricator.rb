Fabricator(:ip_retention, class_name: Vnet::Models::IpRetention) do
end

Fabricator(:ip_retention_with_ip_lease, class_name: Vnet::Models::IpRetention) do
  ip_lease { Fabricate(:ip_lease) }
end

Fabricator(:ip_retention_with_container, class_name: Vnet::Models::IpRetention) do
  ip_retention_container { Fabricate(:ip_retention_container) }
end
