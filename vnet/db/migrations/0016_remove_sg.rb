# -*- coding: utf-8 -*-

Sequel.migration do
  up do
    drop_column :interfaces, :ingress_filtering_enabled

    drop_table :security_groups
    drop_table :security_group_interfaces
  end

  down do
    add_column :interfaces, :ingress_filtering_enabled, FalseClass, :null => false

    create_table(:security_groups) do
      primary_key :id
      String :uuid, :unique => true, :null => false
      String :display_name, :null => false

      String :rules, :null => false, :default => ""
      String :description

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false
    end

    create_table(:security_group_interfaces) do
      primary_key :id

      Integer :security_group_id, :index => true, :null => false
      Integer :interface_id, :index => true, :null => false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false

      unique [:interface_id, :security_group_id, :is_deleted]
    end
  end
end
