# -*- coding: utf-8 -*-

Sequel.migration do
  up do
    drop_column :datapaths, :is_connected
    drop_column :datapath_networks, :is_connected
    drop_column :datapath_route_links, :is_connected

    alter_table(:networks) do
      rename_column :network_mode, :mode
      set_column_not_null :domain_name
    end

    alter_table(:interfaces) do
      set_column_default :mode, ''
      set_column_default :enable_filtering, false
      set_column_default :enable_route_translation, false
      set_column_default :enable_routing, false
    end
  end

  down do
    add_column :datapaths, :is_connected, FalseClass, :null=>false, :default=>false
    add_column :datapath_networks, :is_connected, FalseClass, :null=>false
    add_column :datapath_route_links, :is_connected, FalseClass, :null=>false

    alter_table(:networks) do
      rename_column :mode, :network_mode
      set_column_allow_null :domain_name
    end

    alter_table(:interfaces) do
      set_column_default :mode, 'vif'
      set_column_default :enable_filtering, nil
      set_column_default :enable_route_translation, nil
      set_column_default :enable_routing, nil
    end
  end
end
