# -*- coding: utf-8 -*-

module Vnmgr::Models
  class DatapathNetwork < Base

    many_to_one :datapath
    many_to_one :network
    
    def to_hash
      self.values[:datapath_map] = self.datapath.to_hash
      super
    end

    dataset_module do
      def on_segment(datapath)
        join(:datapaths, :id => :datapath_id).where(~{:datapath_networks__datapath_id => datapath.id}).where({:datapaths__dc_segment_id => datapath.dc_segment_id})
      end

      def on_other_segment(datapath)
        join(:datapaths, :id => :datapath_id).where(~{:datapath_networks__datapath_id => datapath.id}).where(~{:datapaths__dc_segment_id => datapath.dc_segment_id})
      end
    end
  end
end
