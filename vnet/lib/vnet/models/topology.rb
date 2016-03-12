# -*- coding: utf-8 -*-

module Vnet::Models

  class Topology < Base
    taggable 'tp'

    plugin :paranoia_is_deleted

    one_to_many :topology_datapaths
    one_to_many :topology_networks
    one_to_many :topology_route_links

    plugin :association_dependencies,
    # 0009_topology
    topology_datapaths: :destroy,
    topology_networks: :destroy,
    topology_route_links: :destroy

  end

end
