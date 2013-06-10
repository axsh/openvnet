# -*- coding: utf-8 -*-

module Vnmgr::Models
  class DatapathNetwork < Base

    many_to_one :datapath
    many_to_one :network
    
  end
end
