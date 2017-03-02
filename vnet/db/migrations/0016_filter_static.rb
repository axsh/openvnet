# -*- coding: utf-8 -*-

Sequel.migration do
  up do
    alter_table(:filter_statics) do
      drop_column :passthrough
      add_column :action, String, :null => false
      rename_column :ipv4_src_address, :src_address
      rename_column :ipv4_dst_address, :dst_address
      rename_column :ipv4_src_prefix, :src_prefix
      rename_column :ipv4_dst_prefix, :dst_prefix
    end
  end

  down do
    alter_table(:filter_statics) do
      add_column :passthrough, FalseClass, :null => false
      drop_column :action
      rename_column :src_address, :ipv4_src_address
      rename_column :dst_address, :ipv4_dst_address
      rename_column :src_prefix, :ipv4_src_prefix
      rename_column :dst_prefix, :ipv4_dst_prefix
    end
  end
end
