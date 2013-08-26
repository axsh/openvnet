# -*- coding: utf-8 -*-
Fabricator(:ip_lease_1, class_name: Vnet::Models::IpLease) do
  uuid 'il-iplease1'
  #network_id
  #interface_id
  #ip_address_id
  #created_at
  #updated_at
  #deleted_at
  is_deleted 0
end

Fabricator(:ip_lease_2, class_name: Vnet::Models::IpLease) do
  #uuid
  #network_id
  #interface_id
  #ip_address_id
  #created_at
  #updated_at
  #deleted_at
  #is_deleted
end
