Sequel.migration do
  up do
    alter_table(:datapath_networks) do
      add_column :interface_id, Integer, :index => true, :null=>true
    end

    alter_table(:datapath_route_links) do
      add_column :interface_id, Integer, :index => true, :null=>true
    end

    alter_table(:tunnels) do
      add_column :src_interface_id, Integer, :index => true
      add_column :dst_interface_id, Integer, :index => true

      set_column_allow_null :src_interface_id, false
      set_column_allow_null :dst_interface_id, false
    end
  end

  down do
    drop_table(:datapath_networks) do
      drop_column :interface_id
    end

    drop_table(:datapath_route_links) do
      drop_column :interface_id
    end

    drop_table(:tunnels) do
      drop_column :src_interface_id
      drop_column :dst_interface_id
    end
  end
end
