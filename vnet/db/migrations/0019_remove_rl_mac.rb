# -*- coding: utf-8 -*-

Sequel.migration do
  up do
    alter_table(:route_links) do
      drop_column :mac_address_id
    end

  end

  down do
    alter_table(:route_links) do
      add_column :mac_address_id, Integer, :index => true
    end
  end
end
