# -*- coding: utf-8 -*-

Sequel.migration do
  up do
    create_table(:topology_layers) do
      primary_key :id

      Integer :overlay_id, :index => true, :null => false
      Integer :underlay_id, :index => true, :null => false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false, :default=>0

      index [:overlay_id, :is_deleted]
      index [:underlay_id, :is_deleted]

      unique [:overlay_id, :underlay_id, :is_deleted]
    end
  end

  down do
    drop_table(:topology_layers)
  end
end
