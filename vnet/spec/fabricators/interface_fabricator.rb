# -*- coding: utf-8 -*-

Fabricator(:interface, class_name: Vnet::Models::Interface) do
end

Fabricator(:active_interface, class_name: Vnet::Models::ActiveInterface) do
end

Fabricator(:interface_w_mac_lease, class_name: Vnet::Models::Interface) do
  mac_leases do
    [
      Fabricate(:mac_lease,
                mac_address: sequence(:mac_address)
               )
    ]
  end
end

Fabricator(:filter_interface, class_name: Vnet::Models::Interface) do
  # We need to set id manually here so we can create ip leases and mac leases
  # This is because of that fucked up relation in the database.
  # ip_leases n---1 interfaces
  # ip_leases n---1 mac_leases n---1 interfaces
  # Because of this we can't just fabricate a mac lease which in turn fabricates
  # an ip lease. We need to manually set interface_id for the ip lease.
  # Therefore we need to explicitly set the id field so we can access it form the
  # attrs variable. Quite the hassle isn't it?
  id { sequence(:interface_ids, 1) }

  # owner_datapath_id 1
  # Fabricate(:interface_port,
  #           interface_id: attrs[:id],
  #           datapath_id: 1)

  ingress_filtering_enabled true

  ip_leases do |attrs|
    [
      Fabricate(:ip_lease_any) do
        interface_id { attrs[:id] }
        mac_lease { Fabricate(:mac_lease_any,
          mac_address: sequence(:mac_address),
          interface_id: attrs[:id]
        )}
        network { Fabricate(:network) }
        ipv4_address { sequence(:ipv4_address, 1) }
      end
    ]
  end

end

Fabricator(:interface_dp1eth0, class_name: Vnet::Models::Interface) do
  uuid 'if-dp1eth0'
  display_name "test-dp1eth0"
  mode "host"
end

Fabricator(:interface_dp2eth0, class_name: Vnet::Models::Interface) do
  uuid 'if-dp2eth0'
  display_name "test-dp2eth0"
  mode "host"
end

Fabricator(:interface_dp3eth0, class_name: Vnet::Models::Interface) do
  uuid 'if-dp3eth0'
  display_name "test-dp3eth0"
  mode "host"
end

Fabricator(:interface_port, class_name: Vnet::Models::InterfacePort) do
end

Fabricator(:interface_port_host, class_name: Vnet::Models::InterfacePort) do
  singular 1
end

Fabricator(:interface_port_eth0, class_name: Vnet::Models::InterfacePort) do
  singular 1
  port_name 'eth0'
end

Fabricator(:interface_port_wanedge, class_name: Vnet::Models::InterfacePort) do
  singular 1
end

Fabricator(:host_port_any, class_name: Vnet::Models::Interface) do
  mode 'host'
end
