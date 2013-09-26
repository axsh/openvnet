# -*- coding: utf-8 -*-

Sequel.migration do
  up do
    create_table(:datapaths) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      String :display_name, :null=>false
      Bignum :ipv4_address
      FalseClass :is_connected, :null=>false, :default => false
      String :dpid, :null=>false
      Integer :dc_segment_id, :index => true
      String :node_id, :null=>false
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
    end

    create_table(:datapath_networks) do
      primary_key :id
      Integer :datapath_id, :index => true, :null=>false
      Integer :network_id, :index => true, :null=>false
      Bignum :broadcast_mac_address, :null=>false
      FalseClass :is_connected, :null=>false
    end

    create_table(:datapath_route_links) do
      primary_key :id
      Integer :datapath_id, :index => true, :null=>false
      Integer :route_link_id, :index => true, :null=>false
      Bignum :mac_address, :null=>false
      FalseClass :is_connected, :null=>false
    end

    create_table(:dc_segments) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
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
      Integer :interface_id, :index => true, :null => false
      Integer :ip_address_id, :index => true, :null=>false
      Integer :alloc_type
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :null=>false
      FalseClass :is_deleted, :null=>false
    end

    create_table(:networks) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      String :display_name, :null=>false
      Bignum :ipv4_network, :null=>false
      Integer :ipv4_prefix, :default=>24, :null=>false
      String :domain_name
      String :network_mode
      FalseClass :editable
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false

      index [:ipv4_network, :ipv4_prefix]
    end

    create_table(:network_services) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      Integer :interface_id, :index => true
      String :display_name, :index => true, :null=>false
      Integer :incoming_port
      Integer :outgoing_port
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
    end

    create_table(:mac_leases) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      Bignum :mac_address, :unique => true, :null=>false
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
    end

    create_table(:routes) do
      primary_key :id
      String :uuid, :unique => true, :null => false
      Integer :interface_id, :index => true
      Integer :route_link_id, :index => true, :null => false

      String :route_type, :default => 'gateway', :null => false
      Bignum :ipv4_address, :null => false
      Integer :ipv4_prefix, :default => 24, :null => false

      Boolean :ingress, :default => true, :null => false
      Boolean :egress,  :default => true, :null => false

      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false
    end

    create_table(:route_links) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      Bignum :mac_address, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
    end

    create_table(:tunnels) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      String :display_name, :index => true, :null => false
      Integer :src_datapath_id, :index => true, :null => false
      Integer :dst_datapath_id, :index => true, :null => false

      index [:src_datapath_id, :dst_datapath_id]
    end

    create_table(:interfaces) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      Integer :network_id, :index => true
      Bignum :mac_address, :null=>false
      String :display_name

      String :mode, :default => 'vif',:null => false

      # Should be a relation allowing for multiple active/owner
      # datapath ids.
      Integer :active_datapath_id, :index => true
      Integer :owner_datapath_id, :index => true

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
    end

  end

  down do
    drop_table(:datapaths,
               :datapath_networks,
               :dhcp_ranges,
               :interfaces,
               :ip_leases,
               :ip_addresses,
               :networks,
               :network_services,
               :mac_leases,
               :routes,
               :route_links,
               :tunnels,
               )
  end
end
