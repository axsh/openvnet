# -*- coding: utf-8 -*-

Sequel.migration do
  up do

    create_table(:active_interfaces) do
      primary_key :id

      Integer :interface_id, :null=>false
      Integer :datapath_id, :null=>false
      String :label, :size=>255
      TrueClass :singular
      String :port_name, :size=>255
      String :port_number, :size=>255
      TrueClass :enable_routing, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      # These should have id_deleted?
      index [:datapath_id]
      index [:interface_id]
      index [:port_name]
      # Should be datapath, interface_id?
      unique [:interface_id, :datapath_id, :is_deleted]
      # Shouldn't it be 'label' first?
      unique [:interface_id, :label, :is_deleted]
      # Shouldn't that be datapath, singular?
      unique [:interface_id, :singular, :is_deleted]
    end
    
    create_table(:active_networks) do
      primary_key :id

      Integer :network_id, :null=>false
      Integer :datapath_id, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      index [:datapath_id, :is_deleted]
      index [:network_id, :is_deleted]
      unique [:network_id, :datapath_id, :is_deleted]
    end
    
    create_table(:active_ports) do
      primary_key :id

      Integer :datapath_id, :null=>false
      String :port_name, :size=>255, :null=>false
      Bignum :port_number, :null=>false
      String :mode, :size=>255, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:port_number), 0)
      
      index [:datapath_id]
      index [:port_name]
      unique [:datapath_id, :port_name, :is_deleted]
      unique [:datapath_id, :port_number, :is_deleted]
    end
    
    create_table(:active_route_links) do
      primary_key :id

      Integer :route_link_id, :null=>false
      Integer :datapath_id, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      index [:datapath_id, :is_deleted]
      index [:route_link_id, :is_deleted]
      unique [:route_link_id, :datapath_id, :is_deleted]
    end
    
    create_table(:active_segments) do
      primary_key :id

      Integer :segment_id, :null=>false
      Integer :datapath_id, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      index [:datapath_id, :is_deleted]
      index [:segment_id, :is_deleted]
      unique [:segment_id, :datapath_id, :is_deleted]
    end
    
    create_table(:datapath_networks) do
      primary_key :id

      Integer :datapath_id, :null=>false
      Integer :network_id, :null=>false
      Integer :interface_id
      Integer :mac_address_id, :null=>false
      Integer :ip_lease_id

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      unique [:datapath_id, :network_id, :is_deleted]
      index [:datapath_id]
      index [:interface_id]
      index [:ip_lease_id]
      index [:mac_address_id]
      index [:network_id]
    end
    
    create_table(:datapath_route_links) do
      primary_key :id

      Integer :datapath_id, :null=>false
      Integer :route_link_id, :null=>false
      Integer :interface_id
      Integer :mac_address_id, :null=>false
      Integer :ip_lease_id

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      unique [:datapath_id, :route_link_id, :is_deleted]
      index [:datapath_id]
      index [:interface_id]
      index [:ip_lease_id]
      index [:mac_address_id]
      index [:route_link_id]
    end
    
    create_table(:datapath_segments) do
      primary_key :id

      Integer :datapath_id, :null=>false
      Integer :segment_id, :null=>false
      Integer :interface_id
      Integer :mac_address_id, :null=>false
      Integer :ip_lease_id

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      unique [:datapath_id, :segment_id, :is_deleted]
      index [:datapath_id, :is_deleted]
      index [:segment_id, :is_deleted]
    end
    
    create_table(:datapaths) do
      primary_key :id

      String :uuid, :size=>255, :null=>false
      String :display_name, :size=>255, :null=>false
      Bignum :dpid, :null=>false
      String :node_id, :size=>255, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      TrueClass :enable_ovs_learn_action, :default=>true, :null=>false
      
      unique [:dpid, :node_id, :is_deleted]
      unique [:uuid]
    end
    
    create_table(:dns_records) do
      primary_key :id

      String :uuid, :size=>255, :null=>false
      Integer :dns_service_id, :null=>false
      String :name, :size=>255, :null=>false
      Bignum :ipv4_address, :null=>false
      Integer :ttl

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      index [:dns_service_id]
      unique [:uuid]
    end
    
    create_table(:dns_services) do
      primary_key :id

      String :uuid, :size=>255, :null=>false
      Integer :network_service_id, :null=>false
      String :public_dns, :size=>255

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      index [:network_service_id]
      unique [:uuid]
    end
    
    create_table(:filter_statics) do
      primary_key :id

      Integer :filter_id, :null=>false
      Bignum :src_address, :null=>false
      Bignum :dst_address, :null=>false
      Integer :src_prefix, :null=>false
      Integer :dst_prefix, :null=>false
      Integer :port_src
      Integer :port_dst
      String :protocol, :size=>255, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      String :action, :size=>255, :null=>false
      
      unique [:filter_id, :src_address, :dst_address, :src_prefix, :dst_prefix, :port_src, :port_dst, :protocol, :is_deleted]
      index [:filter_id]
    end
    
    create_table(:filters) do
      primary_key :id

      String :uuid, :size=>255, :null=>false
      String :mode, :size=>255, :null=>false
      Integer :interface_id
      TrueClass :ingress_passthrough, :null=>false
      TrueClass :egress_passthrough, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      index [:interface_id]
      unique [:uuid]
    end
    
    create_table(:interface_networks) do
      primary_key :id

      Integer :interface_id, :null=>false
      Integer :network_id, :null=>false
      TrueClass :static, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      unique [:interface_id, :network_id, :is_deleted]
      index [:interface_id, :is_deleted]
      index [:network_id, :is_deleted]
    end
    
    create_table(:interface_ports) do
      primary_key :id

      Integer :interface_id, :null=>false
      Integer :datapath_id
      String :port_name, :size=>255
      TrueClass :singular
      String :interface_mode, :size=>255, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      unique [:interface_id, :datapath_id, :is_deleted]
      index [:datapath_id]
      index [:interface_id]
      index [:port_name]
      unique [:port_name, :datapath_id, :singular, :is_deleted]
    end
    
    create_table(:interface_route_links) do
      primary_key :id

      Integer :interface_id, :null=>false
      Integer :route_link_id, :null=>false
      TrueClass :static, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      unique [:interface_id, :route_link_id, :is_deleted]
      index [:interface_id, :is_deleted]
      index [:route_link_id, :is_deleted]
    end
    
    create_table(:interface_segments) do
      primary_key :id

      Integer :interface_id, :null=>false
      Integer :segment_id, :null=>false
      TrueClass :static, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      unique [:interface_id, :segment_id, :is_deleted]
      index [:interface_id, :is_deleted]
      index [:segment_id, :is_deleted]
    end
    
    create_table(:interfaces) do
      primary_key :id

      String :uuid, :size=>255, :null=>false
      String :mode, :size=>255, :null=>false
      String :display_name, :size=>255
      TrueClass :enable_routing, :default=>false, :null=>false
      TrueClass :enable_route_translation, :default=>false, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      TrueClass :enable_filtering, :default=>false, :null=>false
      TrueClass :enable_legacy_filtering, :null=>false
      
      unique [:uuid]
    end
    
    create_table(:ip_addresses) do
      primary_key :id

      Integer :network_id, :null=>false
      Bignum :ipv4_address, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      index [:network_id]
      unique [:network_id, :ipv4_address, :is_deleted]
    end
    
    create_table(:ip_lease_container_ip_leases) do
      primary_key :id

      Integer :ip_lease_container_id, :null=>false
      Integer :ip_lease_id, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      unique [:ip_lease_container_id, :ip_lease_id, :is_deleted]
      index [:ip_lease_container_id]
      index [:ip_lease_id]
    end
    
    create_table(:ip_lease_containers) do
      primary_key :id

      String :uuid, :size=>255, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      unique [:uuid]
    end
    
    create_table(:ip_leases) do
      primary_key :id

      String :uuid, :size=>255, :null=>false
      Integer :interface_id
      Integer :mac_lease_id
      Integer :ip_address_id, :null=>false
      TrueClass :enable_routing, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      unique [:ip_address_id, :is_deleted]
      index [:interface_id]
      index [:ip_address_id]
      index [:mac_lease_id]
      unique [:uuid]
    end
    
    create_table(:ip_range_groups) do
      primary_key :id

      String :uuid, :size=>255, :null=>false
      String :allocation_type, :default=>"incremental", :size=>255, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      unique [:uuid]
    end
    
    create_table(:ip_ranges) do
      primary_key :id

      String :uuid, :size=>255, :null=>false
      Integer :ip_range_group_id, :null=>false
      Bignum :begin_ipv4_address, :null=>false
      Bignum :end_ipv4_address, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      index [:ip_range_group_id]
      unique [:uuid]
    end
    
    create_table(:ip_retention_containers) do
      primary_key :id

      String :uuid, :size=>255, :null=>false
      Integer :lease_time
      Integer :grace_time

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      unique [:uuid]
    end
    
    create_table(:ip_retentions) do
      primary_key :id

      Integer :ip_lease_id, :null=>false
      Integer :ip_retention_container_id, :null=>false
      DateTime :leased_at
      DateTime :released_at

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      index [:ip_lease_id]
      index [:ip_retention_container_id]
    end
    
    create_table(:lease_policies) do
      primary_key :id

      String :uuid, :size=>255, :null=>false
      String :mode, :default=>"simple", :size=>255, :null=>false
      String :timing, :default=>"immediate", :size=>255, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      unique [:uuid]
    end
    
    create_table(:lease_policy_base_interfaces) do
      primary_key :id

      Integer :lease_policy_id, :null=>false
      Integer :interface_id, :null=>false
      String :label, :size=>255

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      index [:interface_id]
      index [:lease_policy_id]
    end
    
    create_table(:lease_policy_base_networks) do
      primary_key :id

      Integer :lease_policy_id, :null=>false
      Integer :network_id, :null=>false
      Integer :ip_range_group_id, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      index [:ip_range_group_id]
      index [:lease_policy_id]
      index [:network_id]
    end
    
    create_table(:lease_policy_ip_lease_containers) do
      primary_key :id

      Integer :lease_policy_id, :null=>false
      Integer :ip_lease_container_id, :null=>false
      String :label, :size=>255

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      unique [:lease_policy_id, :ip_lease_container_id, :is_deleted]
      index [:ip_lease_container_id]
      index [:lease_policy_id]
    end
    
    create_table(:lease_policy_ip_retention_containers) do
      primary_key :id

      Integer :lease_policy_id, :null=>false
      Integer :ip_retention_container_id, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      index [:ip_retention_container_id], :name=>:container_id_index
      unique [:lease_policy_id, :ip_retention_container_id, :is_deleted]
      index [:lease_policy_id]
    end
    
    create_table(:mac_addresses) do
      primary_key :id

      String :uuid, :size=>255, :null=>false
      Bignum :mac_address, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      Integer :segment_id
      
      unique [:mac_address, :is_deleted]
      unique [:uuid]
    end
    
    create_table(:mac_leases) do
      primary_key :id

      String :uuid, :size=>255, :null=>false
      Integer :interface_id
      Integer :mac_address_id, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      index [:interface_id]
      index [:mac_address_id]
      unique [:uuid]
    end
    
    create_table(:mac_range_groups) do
      primary_key :id

      String :uuid, :size=>255, :null=>false
      String :allocation_type, :default=>"random", :size=>255, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      unique [:uuid]
    end
    
    create_table(:mac_ranges) do
      primary_key :id

      String :uuid, :size=>255, :null=>false
      Integer :mac_range_group_id, :null=>false
      Bignum :begin_mac_address, :null=>false
      Bignum :end_mac_address, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      index [:mac_range_group_id]
      unique [:uuid]
    end
    
    create_table(:network_services) do
      primary_key :id

      String :uuid, :size=>255, :null=>false
      String :display_name, :size=>255
      String :mode, :size=>255, :null=>false
      Integer :interface_id
      Integer :incoming_port
      Integer :outgoing_port

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      index [:interface_id]
      index [:mode], :name=>:network_services_type_index
      unique [:uuid]
    end
    
    create_table(:networks) do
      primary_key :id

      String :uuid, :size=>255, :null=>false
      String :display_name, :size=>255, :null=>false
      Bignum :ipv4_network, :null=>false
      Integer :ipv4_prefix, :default=>24, :null=>false
      String :mode, :size=>255
      String :domain_name, :size=>255, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      Integer :segment_id
      
      index [:ipv4_network, :ipv4_prefix, :is_deleted]
      unique [:uuid]
    end
    
    create_table(:route_links) do
      primary_key :id

      String :uuid, :size=>255, :null=>false
      Integer :mac_address_id

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      index [:mac_address_id]
      unique [:uuid]
    end
    
    create_table(:routes) do
      primary_key :id

      String :uuid, :size=>255, :null=>false
      String :mode, :default=>"gateway", :size=>255, :null=>false
      Integer :interface_id
      Integer :route_link_id, :null=>false
      Integer :network_id, :null=>false
      Bignum :ipv4_network, :null=>false
      Integer :ipv4_prefix, :default=>24, :null=>false
      TrueClass :ingress, :default=>true, :null=>false
      TrueClass :egress, :default=>true, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      index [:interface_id]
      index [:route_link_id]
      unique [:uuid]
    end
    
    create_table(:segments) do
      primary_key :id

      String :uuid, :size=>255, :null=>false
      String :mode, :size=>255, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      unique [:uuid]
    end
    
    create_table(:topologies) do
      primary_key :id

      String :uuid, :size=>255, :null=>false
      String :mode, :size=>255, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      unique [:uuid]
    end
    
    create_table(:topology_datapaths) do
      primary_key :id

      Integer :topology_id, :null=>false
      Integer :datapath_id, :null=>false
      Integer :interface_id, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      index [:topology_id]
      unique [:topology_id, :datapath_id, :is_deleted]
    end
    
    create_table(:topology_layers) do
      primary_key :id

      Integer :overlay_id, :null=>false
      Integer :underlay_id, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      unique [:overlay_id, :underlay_id, :is_deleted]
      index [:overlay_id]
      index [:overlay_id, :is_deleted]
      index [:underlay_id]
      index [:underlay_id, :is_deleted]
    end
    
    create_table(:topology_networks) do
      primary_key :id

      Integer :topology_id, :null=>false
      Integer :network_id, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      unique [:topology_id, :network_id, :is_deleted]
      index [:topology_id]
    end
    
    create_table(:topology_route_links) do
      primary_key :id

      Integer :topology_id, :null=>false
      Integer :route_link_id, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      unique [:topology_id, :route_link_id, :is_deleted]
      index [:topology_id]
    end
    
    create_table(:topology_segments) do
      primary_key :id

      Integer :topology_id, :null=>false
      Integer :segment_id, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      unique [:topology_id, :segment_id, :is_deleted]
      index [:topology_id]
    end
    
    create_table(:translation_static_addresses) do
      primary_key :id

      Integer :translation_id, :null=>false
      Integer :route_link_id
      Bignum :ingress_ipv4_address, :null=>false
      Bignum :egress_ipv4_address, :null=>false
      Integer :ingress_port_number
      Integer :egress_port_number

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      unique [:translation_id, :ingress_ipv4_address, :egress_ipv4_address, :ingress_port_number, :egress_port_number, :is_deleted]
      index [:translation_id]
    end
    
    create_table(:translations) do
      primary_key :id

      String :uuid, :size=>255, :null=>false
      String :mode, :size=>255, :null=>false
      Integer :interface_id
      TrueClass :passthrough, :default=>false, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      index [:interface_id]
      unique [:uuid]
    end
    
    create_table(:tunnels) do
      primary_key :id

      String :uuid, :size=>255, :null=>false
      String :mode, :size=>255, :null=>false
      Integer :src_datapath_id, :null=>false
      Integer :dst_datapath_id, :null=>false
      Integer :src_interface_id, :null=>false
      Integer :dst_interface_id, :null=>false

      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :default=>0, :null=>false
      
      unique [:src_datapath_id, :dst_datapath_id, :src_interface_id, :dst_interface_id, :is_deleted]
      index [:dst_datapath_id]
      index [:dst_interface_id]
      index [:src_datapath_id]
      index [:src_interface_id]
      unique [:uuid]
    end
  end

  down do
  end

end
