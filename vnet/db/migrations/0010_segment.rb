# -*- coding: utf-8 -*-

Sequel.migration do
  up do

    create_table(:segments) do
      primary_key :id
      String :uuid, :unique => true, :null=>false

      String :mode, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false, :default=>0
    end

  end

  down do
    drop_table(:segments,
               )
  end
end
