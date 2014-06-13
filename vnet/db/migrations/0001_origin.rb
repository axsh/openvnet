# -*- coding: utf-8 -*-

Sequel.migration do
  up do

    # Interfaces can be active on multiple datapaths if a 'label' is
    # set and 'singular' is NULL.
    #
    # Both 'label' and 'singular' should not be set to NULL.
    create_table(:active_interfaces) do
      primary_key :id

      Integer :interface_id, :index => true, :null => false
      Integer :datapath_id, :index => true, :null => false
      String :port_name, :index => true

      String :label
      TrueClass :singular

      FalseClass :enable_routing, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false

      index [:interface_id, :datapath_id], :unique => true
      index [:interface_id, :label], :unique => true
      unique [:interface_id, :singular]
    end

    create_table(:datapaths) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      String :display_name, :null=>false
      FalseClass :is_connected, :null=>false, :default => false
      Bignum :dpid, :null=>false
      String :node_id, :null=>false
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
    end

    create_table(:datapath_networks) do
      primary_key :id
      Integer :datapath_id, :index => true, :null=>false
      Integer :network_id, :index => true, :null=>false

      Integer :interface_id, :index => true, :null=>true
      Integer :mac_address_id, :index => true
      Integer :ip_lease_id, :index => true

      FalseClass :is_connected, :null=>false

      DateTime :deleted_at, :index => true
      Integer :deleted, :default => 0, :null => false

      index [:datapath_id, :network_id, :deleted], :unique => true
    end

    create_table(:datapath_route_links) do
      primary_key :id
      Integer :datapath_id, :index => true, :null=>false
      Integer :route_link_id, :index => true, :null=>false

      Integer :interface_id, :index => true, :null=>true
      Integer :mac_address_id, :index => true
      Integer :ip_lease_id, :index => true

      FalseClass :is_connected, :null=>false
    end

    create_table(:dns_services) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      Integer :network_service_id, :index => true, :null => false
      String :public_dns
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at
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
      DateTime :deleted_at
    end

    create_table(:interfaces) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      String :mode, :default => 'vif',:null => false
      String :display_name

      String :port_name, :index => true, :null => true

      Integer :owner_datapath_id, :index => true

      FalseClass :ingress_filtering_enabled, :null => false
      FalseClass :enable_routing, :null=>false
      FalseClass :enable_route_translation, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
    end

    create_table(:interface_security_groups) do
      primary_key :id
      Integer :interface_id, :index => true, :null => false
      Integer :security_group_id, :index => true, :null => false
      DateTime :deleted_at
    end

    create_table(:ip_addresses) do
      primary_key :id
      Integer :network_id, :index => true, :null => false
      Bignum :ipv4_address, :null=>false
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :deleted, :default => 0, :null => false
      unique [:network_id, :ipv4_address, :deleted]
    end

    create_table(:ip_leases) do
      primary_key :id
      String :uuid, :unique => true, :null=>false

      Integer :interface_id, :index => true
      Integer :mac_lease_id, :index => true
      Integer :ip_address_id, :index => true, :null=>false

      FalseClass :enable_routing, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at
    end

    create_table(:ip_lease_containers) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
    end

    create_table(:ip_lease_container_ip_leases) do
      primary_key :id
      Integer :ip_lease_container_id, :index => true, :null => false
      Integer :ip_lease_id, :index => true, :null => false
      unique [:ip_lease_container_id, :ip_lease_id]
    end

    create_table(:ip_range_groups) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      String :allocation_type, :null=>false, :default => "incremental"
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at
    end

    create_table(:ip_ranges) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      Integer :ip_range_group_id, :index => true, :null => false
      Bignum :begin_ipv4_address, :null=>false
      Bignum :end_ipv4_address, :null=>false
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at
    end

    create_table(:ip_retentions) do
      primary_key :id
      Integer :ip_lease_id, :index => true, :null => false
      Integer :ip_retention_container_id, :index => true, :null => false
      DateTime :leased_at
      DateTime :released_at
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
    end

    create_table(:ip_retention_containers) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      Integer :lease_time
      Integer :grace_time
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at
    end

    create_table(:lease_policies) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      String :mode, :null=>false, :default => "simple"
      String :timing, :null=>false, :default => "immediate"
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at
    end

    create_table(:lease_policy_base_interfaces) do
      primary_key :id
      Integer :lease_policy_id, :index => true, :null => false
      Integer :interface_id, :index => true, :null => false
      String :label
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at
    end

    create_table(:lease_policy_base_networks) do
      primary_key :id
      Integer :lease_policy_id, :index => true, :null => false
      Integer :network_id, :index => true, :null => false
      Integer :ip_range_group_id, :index => true, :null => false
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at
    end

    create_table(:lease_policy_ip_lease_containers) do
      primary_key :id
      Integer :lease_policy_id, :index => true, :null => false
      Integer :ip_lease_container_id, :index => true, :null => false
      String :label
      unique [:lease_policy_id, :ip_lease_container_id]
    end

    create_table(:lease_policy_ip_retention_containers) do
      primary_key :id
      Integer :lease_policy_id, :index => true, :null => false
      Integer :ip_retention_container_id, :null => false
      index :ip_retention_container_id, :name => :container_id_index
      unique [:lease_policy_id, :ip_retention_container_id]
    end

    create_table(:mac_addresses) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      Bignum :mac_address, :unique => true, :null=>false
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
    end

    create_table(:mac_leases) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      Integer :interface_id, :index => true
      Integer :mac_address_id, :index => true, :null => false
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at
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
      DateTime :deleted_at, :index => true
      Integer :deleted, :default => 0, :null => false
      index [:ipv4_network, :ipv4_prefix, :deleted]
    end

    create_table(:network_services) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      Integer :interface_id, :index => true
      String :display_name
      String :type, :index => true, :null=>false
      Integer :incoming_port
      Integer :outgoing_port
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
    end

    create_table(:routes) do
      primary_key :id
      String :uuid, :unique => true, :null => false
      Integer :interface_id, :index => true
      Integer :route_link_id, :index => true, :null => false

      String :route_type, :default => 'gateway', :null => false

      # Change network id to segment id once supported.
      Integer :network_id, :null => false
      Bignum  :ipv4_network, :null => false
      Integer :ipv4_prefix, :default => 24, :null => false

      Boolean :ingress, :default => true, :null => false
      Boolean :egress,  :default => true, :null => false

      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false
    end

    create_table(:route_links) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      Integer :mac_address_id, :index => true

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
    end

    create_table(:security_groups) do
      primary_key :id
      String :uuid, :unique => true, :null => false
      String :display_name, :null => false
      String :rules, :null => false, :default => ""
      String :description
      DateTime :deleted_at
    end

    create_table(:translations) do
      primary_key :id
      String :uuid, :unique => true, :null => false

      Integer :interface_id, :index => true
      String :mode, :null => false

      Boolean :passthrough, :default => false, :null => false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at
    end

    create_table(:translation_static_addresses) do
      primary_key :id

      Integer :translation_id, :index => true, :null => false
      Integer :route_link_id

      Bignum :ingress_ipv4_address, :null => false
      Bignum :egress_ipv4_address, :null => false

      Integer :ingress_port_number
      Integer :egress_port_number

      # We depend on SQL handling of null elements in unique to ensure
      # that equival addresses with non-null port numbers cannot be
      # added if an entry with null port numbers already exists.
      unique [:translation_id,
              :ingress_ipv4_address,
              :egress_ipv4_address,
              :ingress_port_number,
              :egress_port_number]
    end

    create_table(:tunnels) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      String :mode, :null=>false

      Integer :src_datapath_id, :index => true, :null => false
      Integer :dst_datapath_id, :index => true, :null => false
      Integer :src_interface_id, :index => true, :null => false
      Integer :dst_interface_id, :index => true, :null => false

      DateTime :deleted_at, :index => true
      Integer :deleted, :default => 0, :null => false

      index [:src_datapath_id, :dst_datapath_id, :src_interface_id, :dst_interface_id, :deleted], :unique => true, :name => :tunnels_datapath_id_interface_id_index
    end

    create_table(:vlan_translations) do
      primary_key :id
      String :uuid, :unique => true, :null => false
      Integer :translation_id, :index => true
      Bignum :mac_address
      Integer :vlan_id
      Integer :network_id
    end
  end

  down do
    drop_table(:datapaths,
               :datapath_networks,
               :datapath_route_links,
               :interfaces,
               :interface_security_groups,
               :ip_addresses,
               :ip_leases,
               :ip_lease_containers,
               :ip_lease_container_ip_leases,
               :ip_range_groups,
               :ip_ranges,
               :ip_retentions,
               :ip_retention_containers,
               :lease_policies,
               :lease_policy_base_interfaces,
               :lease_policy_base_networks,
               :lease_policy_ip_lease_containers,
               :lease_policy_ip_retention_containers,
               :mac_addresses,
               :mac_leases,
               :networks,
               :network_services,
               :routes,
               :route_links,
               :security_groups,
               :translation,
               :translation_static_addresses,
               :tunnels,
               :vlan_translations
               )
  end
end
