# -*- coding: utf-8 -*-

Sequel.migration do
  up do
    create_table(:datapaths) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      Integer :open_flow_controller_id, :index => true, :null=>false
      String :display_name, :null=>false
      Integer :ipv4_address
      FalseClass :is_connected, :null=>false
      String :datapath_id, :null=>false
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
    end

    create_table(:datapath_networks) do
      primary_key :id
      Integer :datapath_id, :index => true, :null=>false
      Integer :network_id, :index => true, :null=>false
      Bignum :broadcast_mac_addr, :null=>false
      FalseClass :is_connected, :null=>false
    end

    create_table(:dc_networks) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      Integer :parent_id, :index => true
      String :display_name, :null => false
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
    end

    create_table(:dhcp_ranges) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      Bignum :range_begin, :null=>false
      Bignum :range_end, :null=>false
      Integer :network_id, :index => true, :null => false
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
    end

    create_table(:networks) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      String :display_name, :null=>false
      Bignum :ipv4_network, :null=>false
      Integer :ipv4_prefix, :default=>24, :null=>false
      String :domain_name
      Integer :dc_network_id, :index => true
      String :network_mode
      FalseClass :editable
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false

      index [:ipv4_network, :ipv4_prefix]
    end

    create_table(:network_services) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      Integer :vif_id, :index => true
      String :display_name, :index => true, :null=>false
      Integer :incoming_port
      Integer :outgoing_port
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
    end

    create_table(:vifs) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      Integer :network_id, :index => true
      Bignum :mac_addr, :null=>false
      String :state, :null=>false
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
    end

    create_table(:routers) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      Integer :network_id, :index => true
      Bignum :ipv4_address, :null=>false
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
    end

    create_table(:tunnels) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      Integer :src_network_id, :index => true, :null => false
      Integer :dst_network_id, :index => true, :null => false
      Integer :tunnel_id, :index => true
      DateTime :ttl
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false

      index [:src_network_id, :dst_network_id]
    end

    create_table(:mac_ranges) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      Bignum :vendor_id, :null=>false
      Bignum :range_begin, :null=>false
      Bignum :range_end, :null=>false
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
    end

    create_table(:mac_leases) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      Bignum :mac_addr, :unique => true, :null=>false
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
    end

    create_table(:ip_addresses) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      Bignum :ipv4_address, :null=>false
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
    end

    create_table(:ip_leases) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      Integer :network_id, :index => true, :null => false
      Integer :vif_id, :index => true, :null => false
      Integer :ip_address_id, :index => true, :null=>false
      Integer :alloc_type
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :null=>false
      FalseClass :is_deleted, :null=>false
    end

    create_table(:open_flow_controllers) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
    end

  end

  down do
    drop_table(:datapaths,
               :datapath_networks,
               :dc_networks,
               :dhcp_ranges,
               :networks,
               :network_services,
               :vifs,
               :routers,
               :tunnels,
               :mac_ranges,
               :mac_leases,
               :ip_leases,
               :ip_addresses,
               :open_flow_controllers,
               )
  end
end
