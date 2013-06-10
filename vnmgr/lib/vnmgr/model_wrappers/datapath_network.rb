# -*- coding: utf-8 -*-

module Vnmgr::ModelWrappers
  class DatapathNetwork < Base
    def to_hash
      {
        :datapath_uuid => self.datapath_uuid,
        :network_uuid => self.network_uuid,
      }
    end
  end
end
