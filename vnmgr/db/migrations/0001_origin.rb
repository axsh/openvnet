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
      column :dc_network_id, 'int(11)'
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
      index [:mac_addr], :unique=>true
    end

    create_table(:routers) do
      primary_key :id, :type => 'int(11)'
      column :uuid, 'varchar(255)', :null=>false
      column :network_id, 'int(11)', :null=>false
      column :ipv4_address, 'int unsigned', :null=>false
      column :created_at, 'datetime', :null=>false
      column :updated_at, 'datetime', :null=>false

      index [:uuid], :unique=>true
      index [:ipv4_address], :unique=>true
    end

    create_table(:network_connections) do
      primary_key :id, :type => 'int(11)'
      column :uuid, 'varchar(255)', :null=>false
      column :src_network_id, 'int(11)', :null=>false
      column :dst_network_id, 'int(11)', :null=>false
      # type = [mac2mac|gre]
      column :type, 'varchar(255)', :null=>false
      column :tunnel_id, 'int(11)', :null=>false
      column :created_at, 'datetime', :null=>false
      column :updated_at, 'datetime', :null=>false

      index [:uuid], :unique=>true
      index [:src_network_id, :dst_network_id]
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
      column :range_begin, 'int(11) unsigned', :null=>false
      column :range_end, 'int(11) unsigned', :null=>false
      column :network_id, 'int(11)', :null=>false
      column :created_at, 'datetime', :null=>false
      column :updated_at, 'datetime', :null=>false

      index [:network_id]
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
      column :mac_addr, 'bigint unsigned', :null=>false
      column :created_at, 'datetime', :null=>false
      column :updated_at, 'datetime', :null=>false

      index [:mac_addr], :unique=>true
    end

    create_table(:ip_leases) do
      primary_key :id, :type => 'int(11)'
      column :network_id, 'int(11)', :null=>false
      column :vif_id, 'int(11)', :null=>false
      column :ip_handle_id, 'int(11)', :null=>false
      column :alloc_type, 'int'
      column :created_at, 'datetime', :null=>false
      column :updated_at, 'datetime', :null=>false
      column :deleted_at, 'datetime', :null=>false
      column :is_deleted, 'tinyint(1)', :null=>false

      index [:network_id]
      index [:vif_id]
      index [:ip_handle_id]
    end

    create_table(:ip_addresses) do
      primary_key :id, :type => 'int(11)'
      column :ipv4_address, 'int unsigned', :null=>false
      column :network_id, 'int(11)', :null=>false
      column :created_at, 'datetime', :null=>false
      column :updated_at, 'datetime', :null=>false

      index [:network_id]
    end

    create_table(:network_services) do
      primary_key :id, :type => 'int(11)'
      column :vif_id, 'int(11)'
      column :name, 'varchar(255)', :null=>false
      column :incoming_port, 'int(11)'
      column :outgoing_port, 'int(11)'
      column :created_at, 'datetime', :null=>false
      column :updated_at, 'datetime', :null=>false

      index [:name]
      index [:vif_id, :name]
    end

    create_table(:openflow_controllers) do
      primary_key :id, :type => 'int(11)'
      column :uuid, 'varchar(255)', :null=>false
      column :created_at, 'datetime', :null=>false
      column :updated_at, 'datetime', :null=>false

      index [:uuid], :unique=>true
    end

    create_table(:datapaths) do
      primary_key :id, :type => 'int(11)'
      column :name, 'varchar(255)', :null=>false
      column :openflow_controller_id, 'int(11)', :null=>false
      column :ipv4_address, 'int unsigned'
      column :created_at, 'datetime', :null=>false
      column :updated_at, 'datetime', :null=>false
      column :is_connected, 'tinyint(1)', :null=>false
      column :datapath_id, 'varchar(255)', :null=>false

      index [:datapath_id], :unique=>true
      index [:openflow_controller_id]
    end
  end

  down do
    drop_table(:networks, :vifs, :routers, :network_connections, :dc_networks, :dhcp_ranges, :mac_ranges, :mac_leases, :ip_leases, :ip_addresses, :network_services, :openflow_controllers, :datapaths)
  end
end
