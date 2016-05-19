# -*- coding: utf-8 -*-

Sequel.migration do
  up do

    create_table(:segments) do
      primary_key :id
      String :uuid, :unique => true, :null=>false

      String :mode, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index=>true
      Integer :is_deleted, :null=>false, :default=>0
    end

    alter_table(:mac_addresses) do
      add_column :segment_id, Integer
      # Add index for segment_id.
    end

    create_table(:datapath_segments) do
      primary_key :id

      # TODO: Review indices and null.
      Integer :datapath_id, :index => true, :null=>false
      Integer :segment_id, :index => true, :null=>false

      Integer :interface_id, :index => true, :null=>true
      Integer :mac_address_id, :index => true, :null=>false
      Integer :ip_lease_id, :index => true

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false, :default=>0

      unique [:datapath_id, :segment_id, :is_deleted]
    end

  end

  down do
    drop_table(:segments,
               :datapath_segments,
               )

    alter_table(:mac_addresses) do
      drop_column :segment_id
    end

  end
end
