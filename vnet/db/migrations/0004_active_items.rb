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

  end

  down do
    drop_table(:active_networks,
               )
  end
end
