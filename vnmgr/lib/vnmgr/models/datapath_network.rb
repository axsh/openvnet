# -*- coding: utf-8 -*-

module Vnmgr::Models
  class DatapathNetwork < Base

    many_to_one :datapath
    many_to_one :network
    
    def to_hash
      self.values[:datapath_map] = self.datapath.to_hash
      super
    end

  end
end
