# -*- coding: utf-8 -*-

module Vnmgr::Models
  class Datapath < Base
    taggable 'dp'
    many_to_one :open_flow_controller
    
    one_to_many :datapath_networks
    many_to_many :networks, :join_table => :datapath_networks

    one_to_many :tunnels, :key => :src_datapath_id
    subset(:alives, {})
  end
end
