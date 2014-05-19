Fabricator(:ip_retention, class_name: Vnet::Models::IpRetention) do
  ip_lease { Fabricate(:ip_lease) }
end
