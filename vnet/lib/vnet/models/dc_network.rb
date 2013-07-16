# -*- coding: utf-8 -*-

module Vnet::Models
  class DcNetwork < Base
    taggable 'dcn'

    one_to_many :dc_network_dc_segments
    many_to_many :dc_segments, :join_table => :dc_network_dc_segments
  end
end
