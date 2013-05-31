# -*- coding: utf-8 -*-

module Vnmgr::Models
  class Datapath < Base
    taggable 'dp'
    many_to_one :open_flow_controller
    
    one_to_many :datapath_networks

  end
end
