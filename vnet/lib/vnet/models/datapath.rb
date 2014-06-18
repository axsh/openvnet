# -*- coding: utf-8 -*-

module Vnet::Models
  class Datapath < Base
    taggable 'dp'

    plugin :paranoia

    one_to_many :datapath_networks
    one_to_many :datapath_route_links
    many_to_many :networks, :join_table => :datapath_networks, :conditions => "datapath_networks.deleted_at is null"
    many_to_many :route_links, :join_table => :datapath_route_links

    one_to_many :interfaces_owned, :class => Interface, :key => :owner_datapath_id

    one_to_many :tunnels, :key => :src_datapath_id

    plugin :association_dependencies,
      datapath_networks: :destroy,
      interfaces_owned: :nullify

    subset(:alives, {})

    one_to_many :host_interfaces, :class => Interface do |ds|
      Interface.where({owner_datapath_id: self.id} & {mode: 'host'})
    end

    def dpid_s
      "0x%016x" % dpid
    end

    def peers
      # deleted datapath's datapath_networks should also be deleted
      network_ids = (self.deleted_at ? datapath_networks_dataset.unfiltered.where(datapath_id: self.id) : datapath_networks).map(&:network_id)

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
