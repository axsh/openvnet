# -*- coding: utf-8 -*-

module Vnet::Services

  class TopologyManager < Vnet::Manager
    include Vnet::Constants::Topology

    #
    # Events:
    #
    event_handler_default_drop_all

    subscribe_event TOPOLOGY_INITIALIZED, :load_item
    subscribe_event TOPOLOGY_UNLOAD_ITEM, :unload_item
    subscribe_event TOPOLOGY_CREATED_ITEM, :created_item
    subscribe_event TOPOLOGY_DELETED_ITEM, :unload_item

    subscribe_event TOPOLOGY_NETWORK_ACTIVATED, :network_activated
    subscribe_event TOPOLOGY_NETWORK_DEACTIVATED, :network_deactivated

    subscribe_event TOPOLOGY_SEGMENT_ACTIVATED, :segment_activated
    subscribe_event TOPOLOGY_SEGMENT_DEACTIVATED, :segment_deactivated

    subscribe_event TOPOLOGY_ROUTE_LINK_ACTIVATED, :route_link_activated
    subscribe_event TOPOLOGY_ROUTE_LINK_DEACTIVATED, :route_link_deactivated

    subscribe_event TOPOLOGY_CREATE_DP_NW, :create_dp_network
    subscribe_event TOPOLOGY_CREATE_DP_SEG, :create_dp_segment
    subscribe_event TOPOLOGY_CREATE_DP_RL, :create_dp_route_link

    # TODO: Add events for host interfaces?

    def initialize(info, options = {})
      super
      @log_prefix = "#{self.class.name.to_s.demodulize.underscore}: "
    end

    def do_initialize
      info log_format('loading all topologies')

      # TODO: Redo this so that we poke node_api to send created_item
      # events while in a transaction.

      mw_class.batch.dataset.all.commit.each { |item_map|
        publish(TOPOLOGY_CREATED_ITEM, item_map)
      }
    end

    #
    # Internal methods:
    #

    private

    #
    # Specialize Manager:
    #

    def mw_class
      MW::Topology
    end

    def initialized_item_event
      TOPOLOGY_INITIALIZED
    end

    def item_unload_event
      TOPOLOGY_UNLOAD_ITEM
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
      item_class =
        case item_map.mode
        when MODE_SIMPLE_OVERLAY then Topologies::SimpleOverlay
        when MODE_SIMPLE_UNDERLAY then Topologies::SimpleUnderlay
        else
          return
        end

      item_class.new(map: item_map)
    end

    #
    # Create / Delete events:
    #

    # item created in db on queue 'item.id'
    def created_item(params)
      return if internal_detect_by_id(params)

      internal_new_item(mw_class.new(params))
    end

    #
    # Assoc methods:
    #

    [ [:network, :network_id],
      [:segment, :segment_id],
      [:route_link, :route_link_id],
    ].each { |other_name, other_key|

      # TOPOLOGY_FOO_ACTIVATED on queue [:foo, foo.id]
      define_method "#{other_name}_activated".to_sym do |params|
        begin
          other_id = get_param_packed_id(params)
          datapath_id = get_param_id(params, :datapath_id)

          event_options = {
            datapath_id: datapath_id,
            other_key => other_id
          }

        rescue Vnet::ParamError => e
          handle_param_error(e)
          return
        end

        debug log_format_h("#{other_name} activated", event_options)

        if has_datapath_assoc?(other_key, datapath_id, other_id)
          debug log_format_h("found existing datapath_#{other_name}", event_options)
          return
        end

        item_id = find_id_using_tp_assoc(other_key, datapath_id, other_id) || return

        event_options[:id] = item_id

        if internal_retrieve(id: item_id).nil?
          warn log_format_h("could not retrieve topology associated with #{other_name}", event_options)
          return
        end

        publish(event_create_assoc_name(other_name), event_options)
      end

      # TOPOLOGY_FOO_DEACTIVATED on queue [:foo, foo.id]
      define_method "#{other_name}_deactivated".to_sym do |params|
        debug log_format_h("#{other_name} deactivated", params)
      end

      # TOPOLOGY_CREATE_DP_FOO on queue 'item.id'
      define_method "create_dp_#{other_name}".to_sym do |params|
        debug log_format_h("creating datapath_#{other_name}", params)

        item = internal_detect_by_id(params) || return

        begin
          item.create_dp_assoc(other_name, params)
        rescue Vnet::ParamError => e
          handle_param_error(e)
        end
      end

    }

    #
    # Helper methods:
    #

    def mw_datapath_assoc_class(other_name)
      case other_name
      when :network, :network_id
        MW::DatapathNetwork
      when :segment, :segment_id
        MW::DatapathSegment
      when :route_link, :route_link_id
        MW::DatapathRouteLink
      else
        raise NotImplementedError
      end
    end

    def mw_topology_assoc_class(other_name)
      case other_name
      when :network, :network_id
        MW::TopologyNetwork
      when :segment, :segment_id
        MW::TopologySegment
      when :route_link, :route_link_id
        MW::TopologyRouteLink
      else
        raise NotImplementedError
      end
    end

    def event_create_assoc_name(other_name)
      case other_name
      when :network
        TOPOLOGY_CREATE_DP_NW
      when :segment
        TOPOLOGY_CREATE_DP_SEG
      when :route_link
        TOPOLOGY_CREATE_DP_RL
      else
        raise NotImplementedError
      end
    end

    def has_datapath_assoc?(other_key, datapath_id, other_id)
      filter = {
        :datapath_id => datapath_id,
        other_key => other_id
      }

      !mw_datapath_assoc_class(other_key).batch.dataset.where(filter).empty?.commit
    end

    def find_id_using_tp_assoc(other_key, datapath_id, other_id)
      # TODO: Should keep local tp_obj list.
      tp_obj = mw_topology_assoc_class(other_key).batch.dataset.where(other_key => other_id).first.commit

      if tp_obj.nil? || tp_obj.topology_id.nil?
        warn log_format_h("#{other_key} not associated with a topology",
                          datapath_id: datapath_id, other_key => other_id)
        return
      end

      tp_obj.topology_id
    end

    #
    #
    #

    # TODO: Do we really want/need this:

    public

    subscribe_event TOPOLOGY_ADDED_NETWORK, :added_network
    subscribe_event TOPOLOGY_REMOVED_NETWORK, :removed_network

    # TODO: Add subscribe_event that creates this method directly.
    def added_network(params)
      (internal_detect_by_id_with_error(params) || return).tap { |item|
        item.added_network(params)
      }
    end

    def removed_network(params)
      (internal_detect_by_id_with_error(params) || return).tap { |item|
        item.removed_network(params)
      }
    end

    def item_post_install(item, item_map)
      MW::TopologyNetwork.dispatch_added_assocs_for_parent_id(item.id)
      MW::TopologySegment.dispatch_added_assocs_for_parent_id(item.id)
      MW::TopologyRouteLink.dispatch_added_assocs_for_parent_id(item.id)
    end

  end

end
