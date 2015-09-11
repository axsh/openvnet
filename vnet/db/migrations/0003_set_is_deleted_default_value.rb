# -*- coding: utf-8 -*-

def tables_with_is_deleted
  [
    :active_interfaces,
    :datapaths,
    :datapath_networks,
    :datapath_route_links,
    :interfaces,
    :interface_ports,
    :ip_addresses,
    :ip_leases,
    :ip_lease_containers,
    :ip_lease_container_ip_leases,
    :ip_range_groups,
    :ip_ranges,
    :mac_addresses,
    :mac_leases,
    :networks,
    :network_services,
    :routes,
    :route_links,
    :security_groups,
    :security_group_interfaces,
    :translations,
    :translation_static_addresses,
    :tunnels,
    :dns_services,
    :dns_records,
    :ip_retentions,
    :ip_retention_containers,
    :lease_policies,
    :lease_policy_base_interfaces,
    :lease_policy_base_networks,
    :lease_policy_ip_lease_containers,
    :lease_policy_ip_retention_containers
  ]
end

Sequel.migration do
  up do
    tables_with_is_deleted.each do |table|
      set_column_default table, :is_deleted, 0
    end
  end

  down do
    tables_with_is_deleted.each do |table|
      drop_column table, :is_deleted
    end
  end

end
