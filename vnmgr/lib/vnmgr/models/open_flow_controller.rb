# -*- coding: utf-8 -*-

module Vnmgr::Models
  class OpenFlowController < Base
    taggable 'ofc'
    one_to_many :datapath
  end
end
