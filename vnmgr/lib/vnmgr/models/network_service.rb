# -*- coding: utf-8 -*-

module Vnmgr::Models
  class NetworkService < Base
    taggable 'ns'

    many_to_one :vif

    subset(:alives, {})

    def to_hash
      self.values[:vif_map] = self.vif.to_hash
      super
    end
  end
end
