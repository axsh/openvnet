# -*- coding: utf-8 -*-

module Vnet::Core::ActiveSegments

  class Base < Vnet::ItemDpBase
    include Vnet::Openflow::FlowHelpers

    attr_reader :segment_id
    attr_reader :datapath_id

    def initialize(params)
      super

      map = params[:map]

      @segment_id = map.segment_id
      @datapath_id = map.datapath_id
    end

    def mode
      :base
    end

    def log_type
      'active_segment/base'
    end

    def pretty_id
      "#{mode}/#{id}"
    end

    def pretty_properties
      "segment_id:#{@segment_id} datapath_id:#{@datapath_id}"
    end

    def cookie
      @id | COOKIE_TYPE_ACTIVE_SEGMENT
    end

    def to_hash
      Vnet::Core::ActiveSegment.new(id: @id,
                                    mode: self.mode,

                                    segment_id: @segment_id,
                                    datapath_id: @datapath_id)
    end

  end

end
