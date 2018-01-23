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

      @overlays = {}
      @underlays = {}
    end

    def log_type
      'topology/base'
    end

    def to_hash
      Vnet::Services::Topology.new(
        id: @id,
        uuid: @uuid)
    end

    [ [:datapath, :datapath_id],
      [:network, :network_id],
      [:segment, :segment_id],
      [:route_link, :route_link_id],
      [:overlay, :overlay_id],
      [:underlay, :underlay_id],
    ].each { |other_name, other_key|

      define_method "added_#{other_name}".to_sym do |params|
        get_param_id(params, other_key).tap { |assoc_id|
          if other_list(other_name)[assoc_id]
            info log_format_h("adding associated #{other_name} failed, already added", params)
            return
          end

          new_assoc = {
            other_key => get_param_id(params, other_key)
          }

          case other_name
          when :datapath
            new_assoc[:interface_id] = get_param_id(params, :interface_id)
            new_assoc[:ip_lease_id] = get_param_id(params, :ip_lease_id)
          when :underlay
            new_assoc[:datapaths] = {}
          end

          (other_list(other_name)[assoc_id] = new_assoc).tap { |assoc_map|
            handle_added_assoc(other_name, assoc_id, assoc_map)
          }
        }
      end

      define_method "removed_#{other_name}".to_sym do |params|
        get_param_id(params, other_key).tap { |assoc_id|
          other_list(other_name).delete(assoc_id).tap { |assoc_map|
            if assoc_map.nil?
              info log_format_h("removing associated #{other_name} failed, not found", params)
              return
            end

            handle_removed_assoc(other_name, assoc_id, assoc_map)
          }
        }
      end

    }

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

    def other_list(other_name)
      case other_name
      when :datapath then @datapaths
      when :network then @networks
      when :segment then @segments
      when :route_link then @route_links
      when :overlay then @overlays
      when :underlay then @underlays
      else
        raise NotImplementedError
      end
    end

    def handle_added_assoc(other_name, assoc_id, assoc_map)
      debug log_format_h("handle_added_#{other_name}", assoc_id: assoc_id, assoc_map: assoc_map)

      case other_name
      when :datapath then handle_added_datapath(assoc_id, assoc_map)
      when :network then handle_added_network(assoc_id, assoc_map)
      when :segment then handle_added_segment(assoc_id, assoc_map)
      when :route_link then handle_added_route_link(assoc_id, assoc_map)
      when :overlay then handle_added_overlay(assoc_id, assoc_map)
      when :underlay then handle_added_underlay(assoc_id, assoc_map)
      else
        raise NotImplementedError
      end
    end

    def handle_removed_assoc(other_name, assoc_id, assoc_map)
      debug log_format_h("handle_removed_#{other_name}", assoc_id: assoc_id, assoc_map: assoc_map)

      case other_name
      when :datapath then handle_removed_datapath(assoc_id, assoc_map)
      when :network then handle_removed_network(assoc_id, assoc_map)
      when :segment then handle_removed_segment(assoc_id, assoc_map)
      when :route_link then handle_removed_route_link(assoc_id, assoc_map)
      when :overlay then handle_removed_overlay(assoc_id, assoc_map)
      when :underlay then handle_removed_underlay(assoc_id, assoc_map)
      else
        raise NotImplementedError
      end
    end

    def handle_added_datapath(assoc_id, assoc_map)
    end
    alias :handle_added_network :handle_added_datapath
    alias :handle_added_segment :handle_added_datapath
    alias :handle_added_route_link :handle_added_datapath
    alias :handle_added_overlay :handle_added_datapath
    alias :handle_added_underlay :handle_added_datapath
    alias :handle_removed_datapath :handle_added_datapath
    alias :handle_removed_network :handle_added_datapath
    alias :handle_removed_segment :handle_added_datapath
    alias :handle_removed_route_link :handle_added_datapath
    alias :handle_removed_overlay :handle_added_datapath
    alias :handle_removed_underlay :handle_added_datapath
    alias :underlay_added_datapath :handle_added_datapath
    alias :underlay_removed_datapath :handle_added_datapath

    def mw_datapath_assoc_class(other_name)
      case other_name
      when :network
        MW::DatapathNetwork
      when :segment
        MW::DatapathSegment
      when :route_link
        MW::DatapathRouteLink
      else
        raise NotImplementedError
      end
    end

    def create_datapath_other(other_name, create_params)
      mw_datapath_assoc_class(other_name).batch.create(create_params).commit.tap { |result|
        if result
          debug log_format_h("created datapath_#{other_name}", create_params)
        else
          info log_format_h("failed to create datapath_#{other_name}", create_params)
        end
      }
    end

    def find_datapath_assoc_map(datapath_id:)
      _, assoc_map = @datapaths.detect { |assoc_key, assoc_map|
        assoc_map[:datapath_id] == datapath_id
      }

      assoc_map
    end

    def create_dp_other(datapath_id:, other_name:, other_key:, other_id:)
      assoc_map = find_datapath_assoc_map(datapath_id: datapath_id)

      if assoc_map.nil?
        return
      end

      create_params = {
        datapath_id: datapath_id,
        other_key => other_id,

        lease_detection: {
          interface_id: get_param_id(assoc_map, :interface_id)
        }
      }

      create_datapath_other(other_name, create_params)
    end

    def create_dp_other_each_active(other_name:, other_key:, other_id:, each_active_filter:)
      create_params = {
        other_key => other_id,

        each_active_filter: each_active_filter,
        lease_detection: {
          topology_id: @id
        }
      }

      create_datapath_other(other_name, create_params)
    end

  end
end
