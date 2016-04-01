# -*- coding: utf-8 -*-

module Vnet::Models
  class DatapathNetwork < Base

    plugin :paranoia_is_deleted
    plugin :mac_address

    many_to_one :datapath
    many_to_one :network

    many_to_one :interface
    many_to_one :ip_lease

    plugin :association_dependencies,
    # 0001_origin
    _mac_address: :destroy

    # TODO: Remove this.
    def datapath_networks_in_the_same_network
      self.class.eager_graph(:datapath).where(network_id: self.network_id).exclude(datapath_networks__id: self.id).all
    end

  end
end
