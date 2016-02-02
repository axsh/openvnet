# -*- coding: utf-8 -*-

Sequel.migration do
  up do
    alter_table(:datapath_networks) do
      set_column_not_null :mac_address_id
    end

    alter_table(:datapath_route_links) do
      set_column_not_null :mac_address_id
    end
  end

  down do
    alter_table(:datapath_networks) do
      set_column_allow_null :mac_address_id
    end

    alter_table(:datapath_route_links) do
      set_column_allow_null :mac_address_id
    end
  end
end
