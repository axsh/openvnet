# -*- coding: utf-8 -*-

Sequel.migration do
  up do
    alter_table(:datapaths) do
      drop_column :is_connected
    end

    alter_table(:networks) do
      rename_column :network_mode, :mode
    end

    alter_table(:interfaces) do
      set_column_default :enable_filtering, false
      set_column_default :enable_route_translation, false
      set_column_default :enable_routing, false
    end
  end

  down do
    alter_table(:datapaths) do
      add_column :is_connected, FalseClass, :null=>false, :default=>false
    end

    alter_table(:networks) do
      rename_column :mode, :network_mode
    end

    alter_table(:interfaces) do
      set_column_default :enable_filtering, nil
      set_column_default :enable_route_translation, nil
      set_column_default :enable_routing, nil
    end
  end
end
