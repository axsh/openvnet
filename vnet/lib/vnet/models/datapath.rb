# -*- coding: utf-8 -*-

module Vnet::Models

  # TODO: Refactor.
  class Datapath < Base
    taggable 'dp'

    plugin :paranoia

    one_to_many :datapath_networks
    one_to_many :datapath_route_links

    many_to_many :networks, :join_table => :datapath_networks, :conditions => "datapath_networks.deleted_at is null"
    many_to_many :route_links, :join_table => :datapath_route_links, :conditions => "datapath_route_links.deleted_at is null"

    one_to_many :interface_ports
    one_to_many :active_interfaces

    one_to_many :tunnels, :key => :src_datapath_id

    plugin :association_dependencies,
      datapath_networks: :destroy,
      datapath_route_links: :destroy,
      active_interfaces: :destroy,
      interface_ports: :destroy

    def dpid_s
      "0x%016x" % dpid
    end

    def peers
      # deleted datapath's datapath_networks should also be deleted
      if self.deleted_at
        network_ids = datapath_networks_dataset.unfiltered.where(datapath_id: self.id).map(&:network_id)
      else
        network_ids = datapath_networks.map(&:network_id)
      end

      self.class
      .graph(DatapathNetwork.dataset, datapath_id: :id)
      .where(network_id: network_ids)
      .exclude(datapaths__id: self.id)
      .group(:datapaths__id)
      .select_all(:datapaths)
      .all
    end

    dataset_module do
      def find_all_by_network_id(network_id)
        left_join(:datapath_networks, :datapath_id => :id).where(:datapath_networks__network_id => network_id).all
      end
    end

  end
end
