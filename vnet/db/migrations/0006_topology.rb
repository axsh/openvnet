# -*- coding: utf-8 -*-

Sequel.migration do
  up do

    create_table(:topologies) do
      primary_key :id
      String :uuid, :unique => true, :null=>false

      String :mode, :null=>false, :default => "simple_overlay"

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false, :default=>0
    end

  end

  down do
    drop_table(:topologies,
               )
  end
end
