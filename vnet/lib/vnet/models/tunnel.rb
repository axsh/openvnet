# -*- coding: utf-8 -*-

module Vnet::Models
  class Tunnel < Base
    taggable 't'

    plugin :paranoia_is_deleted

    many_to_one :src_datapath, :class => Datapath, :key => :src_datapath_id
    many_to_one :dst_datapath, :class => Datapath, :key => :dst_datapath_id

    many_to_one :src_interface, :class => Interface, :key => :src_interface_id
    many_to_one :dst_interface, :class => Interface, :key => :dst_interface_id

    def self.find_or_create(options)
      super(src_datapath_id: options[:src_datapath_id],
            dst_datapath_id: options[:dst_datapath_id],
            src_interface_id: options[:src_interface_id],
            dst_interface_id: options[:dst_interface_id],
            mode: options[:mode].to_s)
    end
  end
end
