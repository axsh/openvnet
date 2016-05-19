# -*- coding: utf-8 -*-

Sequel.migration do
  up do

    create_table(:active_networks) do
      primary_key :id

      Integer :network_id, :null => false
      Integer :datapath_id, :null => false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false, :default=>0

      index [:network_id, :is_deleted]
      index [:datapath_id, :is_deleted]

      unique [:network_id, :datapath_id, :is_deleted]
    end

    create_table(:active_ports) do
      primary_key :id

      Integer :datapath_id, :index => true, :null => false

      String :port_name, :index => true, :null => false
      column :port_number, 'integer(32) unsigned not null'

      String :mode, :null => false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false, :default=>0

      unique [:datapath_id, :port_name, :is_deleted]
      unique [:datapath_id, :port_number, :is_deleted]
    end

    create_table(:active_route_links) do
      primary_key :id

      Integer :route_link_id, :null => false
      Integer :datapath_id, :null => false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false, :default=>0

      index [:route_link_id, :is_deleted]
      index [:datapath_id, :is_deleted]

      unique [:route_link_id, :datapath_id, :is_deleted]
    end

  end

  down do
    drop_table(:active_networks,
               :active_ports,
               :active_route_links,
               )
  end
end
