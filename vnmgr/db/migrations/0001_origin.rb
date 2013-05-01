Sequel.migration do
  up do
    create_table(:networks) do
			primary_key :id, :type => 'int(11)'
			column :uuid, 'varchar(255)'
			column :display_name, 'varchar(255)'
			column :ipv4_network, 'int unsigned'
			column :prefix, 'int'
			column :domain_name, 'varchar(255)'
			column :network_mode, 'varchar(255)'
			column :editable, 'tinyint(1)'
			column :created_at, 'datetime'
			column :updated_at, 'datetime'
    end

    create_table(:vifs) do
			primary_key :id, :type => 'int(11)'
			column :uuid, 'varchar(255)'
			column :network_id, 'int(11)'
			column :mac_addr, 'bigint(20)'
			column :created_at, 'datetime'
			column :updated_at, 'datetime'
    end

    create_table(:routers) do
			primary_key :id, :type => 'int(11)'
			column :network_id, 'int(11)'
			column :ipv4_address, 'int unsigned'
			column :created_at, 'datetime'
			column :updated_at, 'datetime'
    end

    create_table(:network_connections) do
			primary_key :id, :type => 'int(11)'
			column :src_network_id, 'int(11)'
			column :dst_network_id, 'int(11)'
			column :mode, 'tinyint(1)'
			column :tunnel_id, 'int(11)'
			column :created_at, 'datetime'
			column :updated_at, 'datetime'
    end

    create_table(:dc_networks) do
			primary_key :id, :type => 'int(11)'
			column :uuid, 'varchar(255)'
			column :parent_id, 'int(11)'
			column :display_name, 'varchar(255)'
			column :created_at, 'datetime'
			column :updated_at, 'datetime'
    end

    create_table(:dhcp_ranges) do
			primary_key :id, :type => 'int(11)'
			column :range_begin, 'int(11) unsigned'
			column :range_end, 'int(11) unsigned'
			column :network_id, 'int(11)'
			column :created_at, 'datetime'
			column :updated_at, 'datetime'
    end

    create_table(:mac_ranges) do
			primary_key :id, :type => 'int(11)'
			column :uuid, 'varchar(255)'
			column :vendor_id, 'mediumint(8) unsigned'
			column :range_begin, 'mediumint(8) unsigned'
			column :range_end, 'mediumint(8) unsigned'
			column :created_at, 'datetime'
			column :updated_at, 'datetime'
    end

    create_table(:mac_leases) do
			primary_key :id, :type => 'int(11)'
			column :mac_addr, 'bigint(20) unsigned'
			column :created_at, 'datetime'
			column :updated_at, 'datetime'
    end

    create_table(:ip_leases) do
			primary_key :id, :type => 'int(11)'
			column :network_id, 'int(11)'
			column :vif_id, 'int(11)'
			column :ip_handle_id, 'int(11)'
			column :alloc_type, 'int'
			column :created_at, 'datetime'
			column :updated_at, 'datetime'
			column :deleted_at, 'datetime'
			column :is_deleted, 'int'
    end

    create_table(:ip_addresses) do
			primary_key :id, :type => 'int(11)'
			column :ipv4, 'int unsigned'
			column :network_id, 'int(11)'
			column :created_at, 'datetime'
			column :updated_at, 'datetime'
    end

    create_table(:network_services) do
			primary_key :id, :type => 'int(11)'
			column :vif_id, 'int(11)'
			column :name, 'varchar(255)'
			column :incoming_port, 'int(11)'
			column :outgoing_port, 'int(11)'
			column :created_at, 'datetime'
			column :updated_at, 'datetime'
    end

    create_table(:openflow_controllers) do
			primary_key :id, :type => 'int(11)'
			column :uuid, 'varchar(255)'
			column :created_at, 'datetime'
			column :updated_at, 'datetime'
    end

    create_table(:datapaths) do
			primary_key :id, :type => 'int(11)'
			column :name, 'varchar(255)'
			column :openflow_controller_id, 'int(11)'
			column :ipv4_address, 'int unsigned'
			column :created_at, 'datetime'
			column :updated_at, 'datetime'
			column :is_connected, 'tinyint(1)'
			column :datapath_id, 'varchar(255)'
    end
  end

  down do
    drop_table(:networks, :vifs, :routers, :network_connections, :dc_networks, :dhcp_ranges, :mac_ranges, :mac_leases, :ip_leases, :ip_addresses, :network_services, :openflow_controllers, :datapaths)
  end
end
