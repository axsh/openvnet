# -*- coding: utf-8 -*-

module Vnet::Models
  class Tunnel < Base
    taggable 't'
    many_to_one :src_datapath, :class => Datapath, :key => :src_datapath_id
    many_to_one :dst_datapath, :class => Datapath, :key => :dst_datapath_id
  end
end
