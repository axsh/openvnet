# -*- coding: utf-8 -*-

Sequel.migration do
  up do
    create_table(:networks) do
      primary_key :id, :type => 'int(11)'
      column :uuid, 'varchar(255)', :null=>false
      column :display_name, 'varchar(255)', :null=>false
      column :ipv4_network, 'int unsigned', :null=>false
      column :ipv4_prefix, 'int(5)', :default=>24, :null=>false
      column :domain_name, 'varchar(255)'
      column :dc_network_uuid, 'varchar(255)'
      column :network_mode, 'varchar(255)'
      column :editable, 'tinyint(1)'
      column :created_at, 'datetime', :null=>false
      column :updated_at, 'datetime', :null=>false

      index [:uuid], :unique=>true
      index [:ipv4_network, :ipv4_prefix]
    end

    create_table(:vifs) do
      primary_key :id, :type => 'int(11)'
      column :uuid, 'varchar(255)', :null=>false
      column :network_id, 'int(11)'
      column :mac_addr, 'bigint unsigned', :null=>false
      column :state, 'varchar(255)', :null=>false
      column :created_at, 'datetime', :null=>false
      column :updated_at, 'datetime', :null=>false

      index [:uuid], :unique=>true
    end

    create_table(:routers) do
      primary_key :id, :type => 'int(11)'
      column :uuid, 'varchar(255)', :null=>false
      column :network_id, 'int(11)', :null=>false
      column :ipv4_address, 'int unsigned', :null=>false
      column :created_at, 'datetime', :null=>false
      column :updated_at, 'datetime', :null=>false

      index [:uuid], :unique=>true
    end

    create_table(:tunnels) do
      primary_key :id, :type => 'int(11)'
      column :uuid, 'varchar(255)', :null=>false
      column :src_network_uuid, 'varchar(255)', :null=>false
      column :dst_network_uuid, 'varchar(255)', :null=>false
      column :tunnel_id, 'int(11)', :null=>false
      column :ttl, 'datetime'
      column :created_at, 'datetime', :null=>false
      column :updated_at, 'datetime', :null=>false

      index [:uuid], :unique=>true
      index [:src_network_uuid, :dst_network_uuid]
    end

    create_table(:dc_networks) do
      primary_key :id, :type => 'int(11)'
      column :uuid, 'varchar(255)', :null=>false
      column :parent_id, 'int(11)'
      column :display_name, 'varchar(255)', :null=>false
      column :created_at, 'datetime', :null=>false
      column :updated_at, 'datetime', :null=>false

      index [:uuid], :unique=>true
    end

    create_table(:dhcp_ranges) do
      primary_key :id, :type => 'int(11)'
      column :uuid, 'varchar(255)', :null=>false
      column :range_begin, 'int(11) unsigned', :null=>false
      column :range_end, 'int(11) unsigned', :null=>false
      column :network_uuid, 'varchar(255)', :null=>false
      column :created_at, 'datetime', :null=>false
      column :updated_at, 'datetime', :null=>false

      index [:uuid], :unique=>true
    end

    create_table(:mac_ranges) do
      primary_key :id, :type => 'int(11)'
      column :uuid, 'varchar(255)', :null=>false
      column :vendor_id, 'mediumint unsigned', :null=>false
      column :range_begin, 'mediumint unsigned', :null=>false
      column :range_end, 'mediumint unsigned', :null=>false
      column :created_at, 'datetime', :null=>false
      column :updated_at, 'datetime', :null=>false

      index [:uuid], :unique=>true
    end

    create_table(:mac_leases) do
      primary_key :id, :type => 'int(11)'
      column :uuid, 'varchar(255)', :null=>false
      column :mac_addr, 'bigint unsigned', :null=>false
      column :created_at, 'datetime', :null=>false
      column :updated_at, 'datetime', :null=>false

      index [:mac_addr], :unique=>true
    end

    create_table(:ip_leases) do
      primary_key :id, :type => 'int(11)'
      column :uuid, 'varchar(255)', :null=>false
      column :network_uuid, 'varchar(255)', :null=>false
      column :vif_uuid, 'varchar(255)', :null=>false
      column :ip_address_uuid, 'varchar(255)', :null=>false
      column :alloc_type, 'int'
      column :created_at, 'datetime', :null=>false
      column :updated_at, 'datetime', :null=>false
      column :deleted_at, 'datetime', :null=>false
      column :is_deleted, 'tinyint(1)', :null=>false

      index [:uuid], :unique => true
      index [:network_uuid]
      index [:vif_uuid]
      index [:ip_address_uuid]
    end

    create_table(:ip_addresses) do
      primary_key :id, :type => 'int(11)'
      column :uuid, 'varchar(255)', :null=>false
      column :ipv4_address, 'int unsigned', :null=>false
      column :created_at, 'datetime', :null=>false
      column :updated_at, 'datetime', :null=>false

      index [:uuid], :unique => true
    end

    create_table(:network_services) do
      primary_key :id, :type => 'int(11)'
      column :uuid, 'varchar(255)', :null=>false
      column :vif_uuid, 'varchar(255)'
      column :display_name, 'varchar(255)', :null=>false
      column :incoming_port, 'int(11)'
      column :outgoing_port, 'int(11)'
      column :created_at, 'datetime', :null=>false
      column :updated_at, 'datetime', :null=>false

      index [:uuid], :unique => true
      index [:vif_uuid]
      index [:display_name]
    end

    create_table(:open_flow_controllers) do
      primary_key :id, :type => 'int(11)'
      column :uuid, 'varchar(255)', :null=>false
      column :created_at, 'datetime', :null=>false
      column :updated_at, 'datetime', :null=>false

      index [:uuid], :unique=>true
    end

    create_table(:datapaths) do
      primary_key :id, :type => 'int(11)'
      column :uuid, 'varchar(255)', :null=>false
      column :open_flow_controller_uuid, 'varchar(255)', :null=>false
      column :display_name, 'varchar(255)', :null=>false
      column :ipv4_address, 'int unsigned'
      column :is_connected, 'tinyint(1)', :null=>false
      column :datapath_id, 'varchar(255)', :null=>false
      column :created_at, 'datetime', :null=>false
      column :updated_at, 'datetime', :null=>false

      index [:uuid], :unique=>true
    end
  end

  down do
    drop_table(:networks, :vifs, :routers, :tunnels, :dc_networks, :dhcp_ranges, :mac_ranges, :mac_leases, :ip_leases, :ip_addresses, :network_services, :open_flow_controllers, :datapaths)
  end
end
