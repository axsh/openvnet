# -*- coding: utf-8 -*-

module Vnmgr::Models
  class DatapathNetwork < Base

    taggable 'dn'

    many_to_one :datapath
    many_to_one :network

  end
end
