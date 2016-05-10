# -*- coding: utf-8 -*-

module Vnet::Core

  class SegmentManager < Vnet::Core::Manager

    include Vnet::UpdateItemStates
    include Vnet::Constants::Segment

    #
    # Events:
    #
    event_handler_default_drop_all

    subscribe_event SEGMENT_INITIALIZED, :load_item
    subscribe_event SEGMENT_UNLOAD_ITEM, :unload_item
    subscribe_event SEGMENT_CREATED_ITEM, :created_item
    subscribe_event SEGMENT_DELETED_ITEM, :unload_item

    subscribe_event SEGMENT_UPDATE_ITEM_STATES, :update_item_states

    def initialize(*args)
      super
      @interface_ports = {}
      @interface_segments = {}
    end

    #
    # Interfaces:
    #

    def set_interface_port(interface_id, port)
      debug log_format_h("XXXXXXX set_interface_port", interface_id: interface_id, port: port)

      @interface_ports[interface_id] = port
      segments = @interface_segments[interface_id]

      add_item_ids_to_update_queue(segments) if segments
    end

    def clear_interface_port(interface_id)
      port = @interface_ports.delete(interface_id) || return
      segments = @interface_segments[interface_id]

      add_item_ids_to_update_queue(segments) if segments
    end

    def insert_interface_segment(interface_id, segment_id)
      debug log_format_h("XXXXXXX insert_interface_segment", interface_id: interface_id, segment_id: segment_id)

      segments = @interface_segments[interface_id] ||= []
      return if segments.include? segment_id

      segments << segment_id
      add_item_id_to_update_queue(segment_id) if @interface_ports[interface_id]
    end

    def remove_interface_segment(interface_id, segment_id)
      segments = @interface_segments[interface_id] || return
      return unless segments.delete(segment_id)

      add_item_id_to_update_queue(segment_id) if @interface_ports[interface_id]
    end

    # TODO: Clear port from port manager.
    def remove_interface_from_all(interface_id)
      segments = @interface_segments.delete(interface_id)
      port = @interface_ports.delete(interface_id)

      return unless segments && port

      add_item_ids_to_update_queue(segments)
    end

    #
    # Internal methods:
    #

    def do_initialize
      info log_format('XXXXXXXX loading all segments')

      mw_class.batch.dataset.all.commit.each { |item_map|
        internal_new_item(item_map)
      }
    end

    private

    #
    # Specialize Manager:
    #

    def mw_class
      MW::Segment
    end

    def initialized_item_event
      SEGMENT_INITIALIZED
    end

    def item_unload_event
      SEGMENT_UNLOAD_ITEM
    end

    def update_item_states_event
      SEGMENT_UPDATE_ITEM_STATES
    end

    def match_item_proc_part(filter_part)
      filter, value = filter_part

      case filter
      when :id, :uuid
        proc { |id, item| value == item.send(filter) }
      else
        raise NotImplementedError, filter
      end
    end

    def query_filter_from_params(params)
      filter = []
      filter << {id: params[:id]} if params.has_key? :id
      filter
    end

    def item_initialize(item_map)
      debug log_format_h("XXXXXXXXXXXXXXXXXXX", item_map.to_hash)

      item_class =
        case item_map.mode
        when MODE_PHYSICAL then Segments::Virtual # FIX
        when MODE_VIRTUAL then Segments::Virtual
        else
          return
        end

      item_class.new(dp_info: @dp_info, map: item_map)
    end

    #
    # Create / Delete events:
    #

    def item_pre_install(item, item_map)
      # case item.class
      # when Segments::StaticAddress then load_static_addresses(item, item_map)
      # end
    end

    def item_post_install(item, item_map)
      add_item_id_to_update_queue(item.id)
    end

    # SEGMENT_CREATED_ITEM on queue 'item.id'.
    def created_item(params)
      return if internal_detect_by_id(params)

      internal_new_item(mw_class.new(params))
    end

    # Requires queue ':update_item_states'
    def update_item_state(item)
      debug log_format("update_item_state #{item.to_s}")

      item.update_flows(port_numbers_on_segment(item.id))
    end

    #
    # Helper methods:
    #

    def port_numbers_on_segment(segment_id)
      debug log_format_h("port_numbers_on_segment", segment_id: segment_id)

      port_numbers = []

      @interface_segments.each { |interface_id, segments|
        next unless segments.include? segment_id

        port_numbers << (@interface_ports[interface_id] || next)
      }

      port_numbers
    end

  end

end
