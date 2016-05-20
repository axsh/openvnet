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
      Integer :datapath_id, :null=>false
      Integer :segment_id, :null=>false

      Integer :interface_id
      Integer :mac_address_id, :null=>false
      Integer :ip_lease_id

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index=>true
      Integer :is_deleted, :null=>false, :default=>0

      unique [:datapath_id, :segment_id, :is_deleted]
      index [:datapath_id, :is_deleted]
      index [:segment_id, :is_deleted]
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
