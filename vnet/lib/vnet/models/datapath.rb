# -*- coding: utf-8 -*-

module Vnet::Models
  class Datapath < Base
    taggable 'dp'
    many_to_one :open_flow_controller
    
    one_to_many :datapath_networks
    one_to_many :datapath_route_links
    many_to_many :networks, :join_table => :datapath_networks

    one_to_many :tunnels, :key => :src_datapath_id
    subset(:alives, {})

    one_to_many :on_other_segments, :class => Datapath do |ds|
      Datapath.where(~{:id => self.id} & ~{:dc_segment_id => self.dc_segment_id})
    end

    dataset_module do
      def find_all_by_network_id(network_id)
        left_join(:datapath_networks, :datapath_id => :id).where(:datapath_networks__network_id => network_id).all
      end
    end
  end
end
