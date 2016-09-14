# -*- coding: utf-8 -*-

module Vnet::Core::InterfaceSegments

  class Base < Vnet::ItemDpId
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_reader :cookie

    attr_reader :interface_id
    attr_reader :segment_id

    attr_accessor :static

    def initialize(params)
      super

      map = params[:map]

      @interface_id = get_param_id(map, :interface_id)
      @segment_id = get_param_id(map, :segment_id)
      @static = get_param_bool(map, :static)

      @cookie = self.id | COOKIE_TYPE_INTERFACE_SEGMENT
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
      flows = []

      # TODO: Not the correct way, however it's good enough for now.
      flows << flow_create(table: TABLE_PROMISCUOUS_PORT,
                           goto_table: TABLE_SEGMENT_SRC_CLASSIFIER,
                           priority: 10,
                           match_interface: @interface_id,
                           write_segment: @segment_id)

      # We need to skip the source classifier table due to the remote flag.
      flows << flow_create(table: TABLE_PROMISCUOUS_PORT,
                           goto_table: TABLE_SEGMENT_SRC_MAC_LEARNING,
                           priority: 20,
                           match: {
                             :eth_type => 0x0806
                           },
                           match_interface: @interface_id,
                           write_segment: @segment_id)

      @dp_info.add_flows(flows)
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
