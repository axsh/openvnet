# -*- coding: utf-8 -*-

module Vnet::Core::Segments

  class Base < Vnet::ItemDpUuid
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_reader :cookie

    def initialize(params)
      super

      map = params[:map]

      @cookie = @id | COOKIE_TYPE_SEGMENT
    end

    def mode
      :base
    end

    def log_type
      'segment/base'
    end

    def to_hash
      Vnet::Core::Segment.new(id: @id,
                              uuid: @uuid,
                              mode: mode)
    end

    def uninstall
      @dp_info.del_cookie(@cookie)
    end

  end

end
