# -*- coding: utf-8 -*-

Sequel.migration do
  up do
    alter_table(:datapath_networks) do
      add_column :topology_id, Integer, :null => true
      add_column :topology_layer_id, Integer, :null => true
      add_column :topology_mac_range_group_id, Integer, :null => true
    end

    alter_table(:datapath_segments) do
      add_column :topology_id, Integer, :null => true
      add_column :topology_layer_id, Integer, :null => true
      add_column :topology_mac_range_group_id, Integer, :null => true
    end

    alter_table(:datapath_route_links) do
      add_column :topology_id, Integer, :null => true
      add_column :topology_layer_id, Integer, :null => true
      add_column :topology_mac_range_group_id, Integer, :null => true
    end

    alter_table(:topology_datapaths) do
      add_column :ip_lease_id, Integer, :null => false
    end

    create_table(:topology_mac_range_groups) do
      primary_key :id

      Integer :topology_id, :index => true, :null => false
      Integer :mac_range_group_id, :null => false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false, :default=>0

      unique [:topology_id, :mac_range_group_id, :is_deleted]
    end

    # TODO: Require mac_address_id to dp_*.
  end

  down do
    drop_table(:topology_mac_range_groups)

    alter_table(:datapath_networks) do
      drop_column :topology_id
      drop_column :topology_layer_id
      drop_column :topology_mac_range_group_id
    end

    alter_table(:datapath_segments) do
      drop_column :topology_id
      drop_column :topology_layer_id
      drop_column :topology_mac_range_group_id
    end

    alter_table(:datapath_route_links) do
      drop_column :topology_id
      drop_column :topology_layer_id
      drop_column :topology_mac_range_group_id
    end

    alter_table(:topology_datapaths) do
      drop_column :ip_lease_id
    end
  end
end
