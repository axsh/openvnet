# -*- coding: utf-8 -*-

module Vnet::Models
  class Datapath < Base
    taggable 'dp'
    many_to_one :dc_segment

    one_to_many :datapath_networks
    one_to_many :datapath_route_links
    many_to_many :networks, :join_table => :datapath_networks
    many_to_many :route_links, :join_table => :datapath_route_links

    one_to_many :interfaces_owned, :class => Interface, :key => :owner_datapath_id
    one_to_many :interfaces_active, :class => Interface, :key => :active_datapath_id

    one_to_many :tunnels, :key => :src_datapath_id

    one_to_many :host_interfaces, :class => Interface do |ds|
      Interface.where({owner_datapath_id: self.id} & {mode: 'host'})
    end

    subset(:alives, {})

    dataset_module do
      def on_other_segments(datapath_id)
        dc_segment_id = self.where(id: datapath_id).select(:dc_segment_id)
        self.where(~{id: datapath_id} & ~{dc_segment_id: dc_segment_id})
      end

      def on_same_segment(datapath_id)
        dc_segment_id = self.where(id: datapath_id).select(:dc_segment_id)
        self.where(~{id: datapath_id} & {dc_segment_id: dc_segment_id})
      end

      def find_all_by_network_id(network_id)
        left_join(:datapath_networks, :datapath_id => :id).where(:datapath_networks__network_id => network_id).all
      end
    end
  end
end
