# -*- coding: utf-8 -*-

module Vnet::Models
  class DatapathNetwork < Base
    plugin :paranoia_with_unique_constraint
    plugin :mac_address, :attr_name => :broadcast_mac_address

    many_to_one :datapath
    many_to_one :network

    many_to_one :ip_lease

    dataset_module do
      def on_specific_datapath(datapath)
        ds = self.join(:datapaths, :id => :datapath_id)
        ds = ds.where({:datapath_networks__datapath_id => datapath.id})
        ds = ds.select_all(:datapath_networks)
      end
    end

    def datapath_networks_in_the_same_network
      self.class.eager_graph(:datapath).where(network_id: self.network_id).exclude(datapath_networks__id: self.id).all
    end
  end
end
