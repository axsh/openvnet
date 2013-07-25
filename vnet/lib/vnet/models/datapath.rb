# -*- coding: utf-8 -*-

module Vnet::Models
  class Datapath < Base
    taggable 'dp'
    many_to_one :open_flow_controller
    
    one_to_many :datapath_networks
    many_to_many :networks, :join_table => :datapath_networks

    one_to_many :tunnels, :key => :src_datapath_id
    subset(:alives, {})

    dataset_module do
      def on_other_segment(datapath)
        where(~{:id => datapath.id}).where(~{:dc_segment_id => datapath.dc_segment_id})
      end

      def find_all_by_network_id(network_id)
        left_join(:datapath_networks, :datapath_id => :id).where(:datapath_networks__network_id => network_id).all
      end
    end
  end
end
