# -*- coding: utf-8 -*-

Sequel.migration do
  up do
    rename_column :network_services, :type, :mode
    rename_column :routes, :route_type, :mode
  end

  down do
    rename_column :network_services, :mode, :type
    rename_column :routes, :mode, :route_type
  end
end
