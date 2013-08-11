# -*- coding: utf-8 -*-

module Vnet::Models
  class DatapathRouteLink < Base

    many_to_one :datapath
    many_to_one :route_link

    dataset_module do
      def on_segment(datapath)
        ds = self.join(:datapaths, :id => :datapath_id)
        ds = ds.where(~{:datapath_route_links__datapath_id => datapath.id} &
                      {:datapaths__dc_segment_id => datapath.dc_segment_id})
        ds = ds.select_all(:datapath_route_links)
      end

      def on_other_segment(datapath)
        ds = self.join(:datapaths, :id => :datapath_id)
        ds = ds.where(~{:datapath_route_links__datapath_id => datapath.id} &
                      ~{:datapaths__dc_segment_id => datapath.dc_segment_id})
        ds = ds.select_all(:datapath_route_links)
      end
    end
  end
end
