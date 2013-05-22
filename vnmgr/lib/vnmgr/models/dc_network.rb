# -*- coding: utf-8 -*-

module Vnmgr::Models
  class DcNetwork < Base
    taggable 'dn'
    one_to_many :networks
  end
end
