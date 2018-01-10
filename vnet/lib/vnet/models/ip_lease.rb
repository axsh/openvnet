# -*- coding: utf-8 -*-

module Vnet::Models

  # TODO: Refactor.

  class IpLease < Base
    taggable 'il'

    plugin :paranoia_is_deleted
    plugin :ip_address

    #
    # 0001_origin
    #

    # TODO: Move relations from ip_address plugin.
    # many_to_one :mac_lease

    one_to_many :datapath_networks
    one_to_many :datapath_route_links

    one_to_many :ip_lease_container_ip_leases
    many_to_many :ip_lease_containers, join_table: :ip_lease_container_ip_leases, :conditions => "ip_lease_container_ip_leases.deleted_at is null"

    #
    # 0002_services
    #
    one_to_many :ip_retentions

    plugin :association_dependencies,
    # 0001_origin
    datapath_networks: :destroy,
    datapath_route_links: :destroy,
    ip_address: :destroy,
    ip_lease_container_ip_leases: :destroy,
    # 0002_services
    ip_retentions: :destroy

    dataset_module do
      def all_interface_ids
        self.select_all(:interfaces).distinct(:id).map(:id)
      end

      def join_interfaces
        self.join_table(:inner, :interfaces, interfaces__id: :ip_leases__interface_id)
      end

      def join_interface_ports
        self.join_table(:inner, :interface_ports, interface_ports__id: :ip_leases__interface_id)
      end

      def join_ip_addresses
        self.join(:ip_addresses, ip_addresses__id: :ip_leases__ip_address_id)
      end

      def join_topology_datapaths
        self.join_table(:inner, :topology_datapaths, topology_datapaths__id: :ip_leases__interface_id)
      end

      def where_interface_mode(interface_mode)
        self.join_interfaces.where(mode: interface_mode)
      end

      def where_datapath_id_and_interface_mode(datapath_id, interface_mode)
        self.join_interface_ports.where(datapath_id: datapath_id, interface_mode: interface_mode).select_all(:ip_leases)
      end

      def where_network_id(network_id)
        self.join_ip_addresses.where(ip_addresses__network_id: network_id)
      end

      def where_topology_id(topology_id)
        self.join_topology_datapaths.where(ip_addresses__topology_id: topology_id)
      end
    end

    # TODO: Is this really safe if interface_id is changed?
    # TODO: This could cause issues if we lease/release translation
    # related ip leases often.
    def cookie_id
      self.class.with_deleted.where(interface_id: self.interface_id).where("id <= ?", self.id).count
    end

  end
end
