# -*- coding: utf-8 -*-

module Vnet::Models

  # TODO: Add comments.

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
    one_to_many :src_tunnels, :class => Tunnel, :key => :src_datapath_id
    one_to_many :dst_tunnels, :class => Tunnel, :key => :dst_datapath_id

    plugin :association_dependencies,
      datapath_networks: :destroy,
      datapath_route_links: :destroy,
      active_interfaces: :destroy,
      interface_ports: :destroy,
      src_tunnels: :destroy,
      dst_tunnels: :destroy

    def dpid_s
      "0x%016x" % dpid
    end

  end
end
