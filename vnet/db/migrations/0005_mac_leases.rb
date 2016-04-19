# -*- coding: utf-8 -*-

Sequel.migration do
  up do

    create_table(:mac_ranges) do
      primary_key :id
      String :uuid, :unique => true, :null=>false # Needed?

      Integer :mac_range_group_id, :index => true, :null => false

      Bignum :begin_mac_address, :null=>false
      Bignum :end_mac_address, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false, :default=>0
    end

    create_table(:mac_range_groups) do
      primary_key :id
      String :uuid, :unique => true, :null=>false

      String :allocation_type, :null=>false, :default => "random"

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false, :default=>0
    end

  end

  down do
    drop_table(:mac_ranges,
               :mac_range_groups,
               )
  end
end
