# -*- coding: utf-8 -*-

module Vnet::Models
  class Tunnel < Base
    taggable 't'

    plugin :paranoia_is_deleted

    many_to_one :src_datapath, :class => Datapath, :key => :src_datapath_id
    many_to_one :dst_datapath, :class => Datapath, :key => :dst_datapath_id

    many_to_one :src_interface, :class => Interface, :key => :src_interface_id
    many_to_one :dst_interface, :class => Interface, :key => :dst_interface_id

  end
end
