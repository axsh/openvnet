# -*- coding: utf-8 -*-

module Vnmgr::Models
  class Datapath < Base
    taggable 'dp'
    many_to_one :OpenFlowController
  end
end
