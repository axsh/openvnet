# -*- coding: utf-8 -*-

module Vnet::Models

  # TODO: Refactor partial, fix conditions and add comments. Refactor
  # node_api.

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
    one_to_many :src_tunnels, :key => :src_datapath_id
    one_to_many :dst_tunnels, :key => :dst_datapath_id

    plugin :association_dependencies,
      datapath_networks: :destroy,
      datapath_route_links: :destroy,
      active_interfaces: :destroy,
      interface_ports: :destroy,
      src_datapath_id: :destroy,
      dst_datapath_id: :destroy

    def dpid_s
      "0x%016x" % dpid
    end

  end
end
