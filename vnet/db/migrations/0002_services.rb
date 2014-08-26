# -*- coding: utf-8 -*-

Sequel.migration do
  up do

    create_table(:dns_services) do
      primary_key :id
      String :uuid, :unique => true, :null=>false

      Integer :network_service_id, :index => true, :null => false
      String :public_dns

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false
    end

    create_table(:dns_records) do
      primary_key :id
      String :uuid, :unique => true, :null=>false

      Integer :dns_service_id, :index => true, :null => false

      String :name, :null => false
      Bignum :ipv4_address, :null => false
      Integer :ttl

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false
    end

    create_table(:ip_retentions) do
      primary_key :id

      Integer :ip_lease_id, :index => true, :null => false
      Integer :ip_retention_container_id, :index => true, :null => false

      DateTime :leased_at
      DateTime :released_at

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false
    end

    create_table(:ip_retention_containers) do
      primary_key :id
      String :uuid, :unique => true, :null=>false

      Integer :lease_time
      Integer :grace_time

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false
    end

    create_table(:lease_policies) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      String :mode, :null=>false, :default => "simple"

      String :timing, :null=>false, :default => "immediate"

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false
    end

    create_table(:lease_policy_base_interfaces) do
      primary_key :id

      Integer :lease_policy_id, :index => true, :null => false
      Integer :interface_id, :index => true, :null => false

      String :label

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false
    end

    create_table(:lease_policy_base_networks) do
      primary_key :id

      Integer :lease_policy_id, :index => true, :null => false
      Integer :network_id, :index => true, :null => false
      Integer :ip_range_group_id, :index => true, :null => false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false
    end

    create_table(:lease_policy_ip_lease_containers) do
      primary_key :id

      Integer :lease_policy_id, :index => true, :null => false
      Integer :ip_lease_container_id, :index => true, :null => false

      String :label

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false

      unique [:lease_policy_id, :ip_lease_container_id, :is_deleted]
    end

    create_table(:lease_policy_ip_retention_containers) do
      primary_key :id

      Integer :lease_policy_id, :index => true, :null => false
      Integer :ip_retention_container_id, :null => false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false

      index :ip_retention_container_id, :name => :container_id_index
      unique [:lease_policy_id, :ip_retention_container_id, :is_deleted]
    end

  end

  down do
    drop_table(:dns_services,
               :dns_records,
               :ip_retentions,
               :ip_retention_containers,
               :lease_policies,
               :lease_policy_base_interfaces,
               :lease_policy_base_networks,
               :lease_policy_ip_lease_containers,
               :lease_policy_ip_retention_containers,
               )
  end

end
