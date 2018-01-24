# -*- coding: utf-8 -*-

Sequel.migration do
  up do
    alter_table(:datapath_networks) do
      add_column :topology_id, Integer, :null => true
    end

    alter_table(:datapath_segments) do
      add_column :topology_id, Integer, :null => true
    end

    alter_table(:datapath_route_links) do
      add_column :topology_id, Integer, :null => true
    end

    alter_table(:topology_datapaths) do
      add_column :ip_lease_id, Integer, :null => false
    end
  end

  down do
    alter_table(:datapath_networks) do
      drop_column :topology_id
    end

    alter_table(:datapath_segments) do
      drop_column :topology_id
    end

    alter_table(:datapath_route_links) do
      drop_column :topology_id
    end

    alter_table(:topology_datapaths) do
      drop_column :ip_lease_id
    end
  end
end
