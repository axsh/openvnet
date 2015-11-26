# -*- coding: utf-8 -*-

Sequel.migration do
  up do

    create_table(:filters) do
      primary_key :id
      String :uuid, :unique => true, :null => false
      String :mode, :null => false

      Integer :interface_id, :index => true
      
      FalseClass :ingress_passthrough, :null=> false
      FalseClass :egress_passthrough, :null=>false

      DateTime :created_at, :null =>false
      DateTime :updated_at, :null =>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null =>false
    end
    
    create_table(:filter_statics) do
      primary_key :id
      Integer :filter_id, :index => true, :null => false

      Bignum :ipv4_src_address, :null => false
      Bignum :ipv4_dst_address, :null => false
      Integer :ipv4_src_prefix, :null => false
      Integer :ipv4_dst_prefix, :null => false
      Integer :port_src_first
      Integer :port_dst_first
      Integer :port_src_last
      Integer :port_dst_last
      
      String :protocol, :null => false
      FalseClass :passthrough, :null => false
      
      DateTime :created_at, :null =>false
      DateTime :updated_at, :null =>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null =>false
    end

    alter_table(:interfaces) do
      add_column :enable_filtering, FalseClass, :null=> false
      add_column :enable_legacy_filtering, FalseClass, :null => false
    end
    
  end

  down do
    drop_table(:filters,
               :filter_statics,
              )
    drop_column :interfaces, :enable_filtering
    drop_column :interfaces, :enable_legacy_filtering
  end
end
