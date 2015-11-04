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

      String :label
      TrueClass :singular

      String :port_name, :index => true
      String :port_number

      FalseClass :enable_routing, :null=>false

      # TODO: Consider index for all.
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false

      unique [:interface_id, :datapath_id, :is_deleted]
      unique [:interface_id, :label, :is_deleted]
      unique [:interface_id, :singular, :is_deleted]
    end

    create_table(:datapaths) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      String :display_name, :null=>false

      # TODO: Rename dpid.
      Bignum :dpid, :null=>false
      String :node_id, :null=>false

      FalseClass :is_connected, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false

      # TODO: Add unique for [node_id, dpid], or possibly [dpid].
    end

    create_table(:datapath_networks) do
      primary_key :id

      Integer :datapath_id, :index => true, :null=>false
      Integer :network_id, :index => true, :null=>false

      Integer :interface_id, :index => true, :null=>true
      Integer :mac_address_id, :index => true
      Integer :ip_lease_id, :index => true

      FalseClass :is_connected, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false

      unique [:datapath_id, :network_id, :is_deleted]
    end

    create_table(:datapath_route_links) do
      primary_key :id

      Integer :datapath_id, :index => true, :null=>false
      Integer :route_link_id, :index => true, :null=>false

      Integer :interface_id, :index => true, :null=>true
      Integer :mac_address_id, :index => true
      Integer :ip_lease_id, :index => true

      FalseClass :is_connected, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false

      unique [:datapath_id, :route_link_id, :is_deleted]
    end

      
    create_table(:interfaces) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      String :mode, :default => 'vif',:null => false
      String :display_name

      FalseClass :ingress_filtering_enabled, :null => false
      FalseClass :enable_routing, :null=>false
      FalseClass :enable_route_translation, :null=>false
      
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false
    end

    create_table(:interface_ports) do
      primary_key :id

      Integer :interface_id, :index => true, :null => false
      Integer :datapath_id, :index => true

      String :port_name, :index => true

      TrueClass :singular

      # Temporary work-around until we refactor port manager so that
      # interface_port's can just include an interface_ingress/egress
      # parameter.
      String :interface_mode, :null => false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false

      unique [:interface_id, :datapath_id, :is_deleted]
      unique [:port_name, :datapath_id, :singular, :is_deleted]
    end

    create_table(:ip_addresses) do
      primary_key :id

      Integer :network_id, :index => true, :null => false
      Bignum :ipv4_address, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false

      unique [:network_id, :ipv4_address, :is_deleted]
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
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false

      unique [:ip_address_id, :is_deleted]
    end

    create_table(:ip_lease_containers) do
      primary_key :id
      String :uuid, :unique => true, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false
    end

    create_table(:ip_lease_container_ip_leases) do
      primary_key :id

      Integer :ip_lease_container_id, :index => true, :null => false
      Integer :ip_lease_id, :index => true, :null => false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false

      unique [:ip_lease_container_id, :ip_lease_id, :is_deleted]
    end

    create_table(:ip_range_groups) do
      primary_key :id
      String :uuid, :unique => true, :null=>false

      String :allocation_type, :null=>false, :default => "incremental"

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false
    end

    create_table(:ip_ranges) do
      primary_key :id
      String :uuid, :unique => true, :null=>false

      Integer :ip_range_group_id, :index => true, :null => false

      Bignum :begin_ipv4_address, :null=>false
      Bignum :end_ipv4_address, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false
    end

    create_table(:mac_addresses) do
      primary_key :id
      String :uuid, :unique => true, :null=>false

      Bignum :mac_address, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false

      unique [:mac_address, :is_deleted]
    end

    create_table(:mac_leases) do
      primary_key :id
      String :uuid, :unique => true, :null=>false

      Integer :interface_id, :index => true
      Integer :mac_address_id, :index => true, :null => false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false
    end

    create_table(:networks) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      String :display_name, :null=>false

      Bignum :ipv4_network, :null=>false
      Integer :ipv4_prefix, :default=>24, :null=>false

      # TODO: Rename to 'mode'.
      String :network_mode
      String :domain_name

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false

      index [:ipv4_network, :ipv4_prefix, :is_deleted]
    end

    create_table(:network_services) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      String :display_name

      String :type, :index => true, :null=>false

      Integer :interface_id, :index => true

      Integer :incoming_port
      Integer :outgoing_port

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false
    end

    create_table(:routes) do
      primary_key :id
      String :uuid, :unique => true, :null => false

      # Rename to 'mode'.
      String :route_type, :default => 'gateway', :null => false

      Integer :interface_id, :index => true
      Integer :route_link_id, :index => true, :null => false

      # Change network id to segment id once supported.
      Integer :network_id, :null => false
      Bignum  :ipv4_network, :null => false
      Integer :ipv4_prefix, :default => 24, :null => false

      Boolean :ingress, :default => true, :null => false
      Boolean :egress,  :default => true, :null => false

      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false
    end

    create_table(:route_links) do
      primary_key :id
      String :uuid, :unique => true, :null=>false

      Integer :mac_address_id, :index => true

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false
    end

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

    create_table(:translations) do
      primary_key :id
      String :uuid, :unique => true, :null => false
      String :mode, :null => false

      Integer :interface_id, :index => true

      Boolean :passthrough, :default => false, :null => false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false
    end

    create_table(:translation_static_addresses) do
      primary_key :id

      Integer :translation_id, :index => true, :null => false
      Integer :route_link_id

      Bignum :ingress_ipv4_address, :null => false
      Bignum :egress_ipv4_address, :null => false

      Integer :ingress_port_number
      Integer :egress_port_number

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false

      # We depend on SQL handling of null elements in unique to ensure
      # that equival addresses with non-null port numbers cannot be
      # added if an entry with null port numbers already exists.
      unique [:translation_id,
              :ingress_ipv4_address,
              :egress_ipv4_address,
              :ingress_port_number,
              :egress_port_number,
              :is_deleted]
    end

    create_table(:tunnels) do
      primary_key :id
      String :uuid, :unique => true, :null=>false
      String :mode, :null=>false

      Integer :src_datapath_id, :index => true, :null => false
      Integer :dst_datapath_id, :index => true, :null => false
      Integer :src_interface_id, :index => true, :null => false
      Integer :dst_interface_id, :index => true, :null => false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null=>false

      unique [:src_datapath_id,
              :dst_datapath_id,
              :src_interface_id,
              :dst_interface_id,
              :is_deleted], :name => :tunnels_datapath_id_interface_id_index
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
    drop_table(:active_interfaces,
               :datapaths,
               :datapath_networks,
               :datapath_route_links,
               :interfaces,
               :ip_addresses,
               :ip_leases,
               :ip_lease_containers,
               :ip_lease_container_ip_leases,
               :ip_range_groups,
               :ip_ranges,
               :mac_addresses,
               :mac_leases,
               :networks,
               :network_services,
               :routes,
               :route_links,
               :security_groups,
               :security_group_interfaces,
               :translations,
               :translation_static_addresses,
               :tunnels,
               :vlan_translations,
               )
  end
end
