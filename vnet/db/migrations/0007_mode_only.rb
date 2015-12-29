# -*- coding: utf-8 -*-

Sequel.migration do
  up do
    rename_column :network_services, :type, :mode
  end

  down do
    rename_column :network_services, :mode, :type
  end
end
