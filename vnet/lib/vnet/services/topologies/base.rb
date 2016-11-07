# -*- coding: utf-8 -*-

module Vnet::Services::Topologies
  class Base < Vnet::ItemVnetUuid
    include Celluloid::Logger

    attr_reader :datapaths
    attr_reader :networks
    attr_reader :segments
    attr_reader :route_links

    def initialize(params)
      super

      @datapaths = {}
      @networks = {}
      @segments = {}
      @route_links = {}
    end

    def log_type
      'topology/base'
    end

    def to_hash
      Vnet::Services::Topology.new(
        id: @id,
        uuid: @uuid)
    end

    # TODO: Add to plugin.

    def added_network(params)
      get_param_id(params, :network_id).tap { |assoc_id|
        if @networks[assoc_id]
          info log_format_h('adding assoc network failed, already added', params)
          return
        end

        (@networks[assoc_id] = {}).tap { |assoc_map|
          handle_removed_network(assoc_id, assoc_map)
        }
      }
    end

    def removed_network(params)
      get_param_id(params, :network_id).tap { |assoc_id|
        @networks.delete(assoc_id).tap { |assoc_map|
          if assoc_map.nil?
            info log_format_h('removing assoc network failed, not found', params)
            return
          end

          handle_removed_network(assoc_id, assoc_map)
        }
      }
    end

    def create_dp_assoc(other_name, params)
      case other_name
      when :network
        create_dp_network(params)
      when :segment
        create_dp_segment(params)
      when :route_link
        create_dp_route_link(params)
      else
        raise NotImplementedError
      end
    end

    #
    # Events:
    #

    def install
    end

    def uninstall
    end

    #
    # Internal methods:
    #

    private

    def handle_added_network(assoc_id, assoc_map)
      debug log_format_h('handle_added_network', assoc_id: assoc_id, assoc_map: assoc_map)
    end

    def handle_removed_network(assoc_id, assoc_map)
      debug log_format_h('handle_removed_network', assoc_id: assoc_id, assoc_map: assoc_map)
    end

    #
    #
    #

    def create_datapath_other(other_name, datapath_id, other_id, interface_id)
      case other_name
      when :network
        create_datapath_network(datapath_id, other_id, interface_id)
      when :segment
        create_datapath_segment(datapath_id, other_id, interface_id)
      when :route_link
        create_datapath_route_link(datapath_id, other_id, interface_id)
      else
        raise NotImplementedError
      end
    end

    # TODO: Abstract.
    def create_datapath_network(datapath_id, network_id, interface_id)
      create_params = {
        datapath_id: datapath_id,
        network_id: network_id,
        interface_id: interface_id
      }

      if MW::DatapathNetwork.batch.create(create_params).commit
        debug log_format_h("created datapath_network", create_params)
      else
        info log_format_h("failed to create datapath_network", create_params)
      end
    end

    def create_datapath_segment(datapath_id, segment_id, interface_id)
      create_params = {
        datapath_id: datapath_id,
        segment_id: segment_id,
        interface_id: interface_id
      }

      if MW::DatapathSegment.batch.create(create_params).commit
        debug log_format_h("created datapath_segment", create_params)
      else
        info log_format_h("failed to create datapath_segment", create_params)
      end
    end

    def create_datapath_route_link(datapath_id, route_link_id, interface_id)
      create_params = {
        datapath_id: datapath_id,
        route_link_id: route_link_id,
        interface_id: interface_id
      }

      if MW::DatapathRouteLink.batch.create(create_params).commit
        debug log_format_h("created datapath_route_link", create_params)
      else
        info log_format_h("failed to create datapath_route_link", create_params)
      end
    end

    # Ugly but simple way of getting a host interface.
    def get_a_host_interface_id(datapath_id)
      filter = {
        datapath_id: datapath_id,
        interface_mode: Vnet::Constants::Interface::MODE_HOST
      }

      interface = MW::InterfacePort.batch.dataset.where(filter).first.commit

      debug log_format("get_a_host_interface", interface.inspect)

      interface && interface.interface_id
    end

  end
end
