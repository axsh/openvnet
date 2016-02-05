# -*- coding: utf-8 -*-

Sequel.migration do
  up do

    create_table(:topologies) do
      primary_key :id
      String :uuid, :unique => true, :null=>false

      String :mode, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false, :default=>0
    end

    create_table(:topology_datapaths) do
      primary_key :id

      Integer :topology_id, :index => true, :null => false
      Integer :datapath_id, :null => false

      Integer :interface_id, :null => false
      # On network foo? Using ip lease bar? nil if use first.

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false, :default=>0

      unique [:topology_id, :datapath_id, :is_deleted]
    end

    create_table(:topology_networks) do
      primary_key :id

      Integer :topology_id, :index => true, :null => false
      Integer :network_id, :null => false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false, :default=>0

      # TODO: Only allow network to have be part of one topology?
      unique [:topology_id, :network_id, :is_deleted]
    end

    create_table(:topology_route_links) do
      primary_key :id

      Integer :topology_id, :index => true, :null => false
      Integer :route_link_id, :null => false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false, :default=>0

      unique [:topology_id, :route_link_id, :is_deleted]
    end

  end

  down do
    drop_table(:topologies,
               :topology_datapaths,
               :topology_networks,
               :topology_route_links,
               )
  end
end
