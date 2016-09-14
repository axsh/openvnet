# -*- coding: utf-8 -*-

module Vnet::Core::InterfaceSegments

  class Base < Vnet::ItemDpId
    attr_reader :interface_id
    attr_reader :segment_id

    attr_accessor :static

    def initialize(params)
      super

      map = params[:map]

      @interface_id = get_param_id(map, :interface_id)
      @segment_id = get_param_id(map, :segment_id)
      @static = get_param_bool(map, :static)
    end

    def mode
      :base
    end

    def log_type
      'interface_segment/base'
    end

    def pretty_id
      "#{mode}/#{id}"
    end

    def pretty_properties
      "interface_id:#{@interface_id} segment_id:#{@segment_id}" + (@static ? ' static' : '')
    end

    def install
      @dp_info.segment_manager.insert_interface_segment(@interface_id, @segment_id)
    end

    def uninstall
      @dp_info.segment_manager.remove_interface_segment(@interface_id, @segment_id)
    end

    def to_hash
      Vnet::Core::InterfaceSegment.new(
        id: @id,
        interface_id: @interface_id,
        segment_id: @segment_id,
        static: @static
      )
    end

  end

end
