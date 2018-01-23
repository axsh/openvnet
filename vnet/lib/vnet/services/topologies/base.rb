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

    def added_assoc(other_name, params)
      case other_name
      when :datapath then added_datapath(params)
      when :network then added_network(params)
      when :segment then added_segment(params)
      when :route_link then added_route_link(params)
      else
        raise NotImplementedError
      end
    end

    def removed_assoc(other_name, params)
      case other_name
      when :datapath then removed_datapath(params)
      when :network then removed_network(params)
      when :segment then removed_segment(params)
      when :route_link then removed_route_link(params)
      else
        raise NotImplementedError
      end
    end

    [ [:datapath, :datapath_id, :@datapaths],
      [:network, :network_id, :@networks],
      [:segment, :segment_id, :@segments],
      [:route_link, :route_link_id, :@route_links],
      [:overlay, :overlay_id, :@overlays],
      [:underlay, :underlay_id, :@underlays],
    ].each { |other_name, other_key, other_member|

      define_method "added_#{other_name}".to_sym do |params|
        get_param_id(params, other_key).tap { |assoc_id|
          if instance_variable_get(other_member)[assoc_id]
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

          (instance_variable_get(other_member)[assoc_id] = new_assoc).tap { |assoc_map|
            handle_added_assoc(other_name, assoc_id, assoc_map)
          }
        }
      end

      define_method "removed_#{other_name}".to_sym do |params|
        get_param_id(params, other_key).tap { |assoc_id|
          instance_variable_get(other_member).delete(assoc_id).tap { |assoc_map|
            if assoc_map.nil?
              info log_format_h("removing associated #{other_name} failed, not found", params)
              return
            end

            handle_removed_assoc(other_name, assoc_id, assoc_map)
          }
        }
      end

    }

    def create_underlay(params)
      raise NotImplementedError
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

    def handle_added_assoc(other_name, assoc_id, assoc_map)
      debug log_format_h("handle_added_#{other_name}", assoc_id: assoc_id, assoc_map: assoc_map)

      case other_name
      when :datapath then handle_added_datapath(assoc_id, assoc_map)
      when :network then handle_added_network(assoc_id, assoc_map)
      when :segment then handle_added_segment(assoc_id, assoc_map)
      # when :route_link then handle_added_route_link(assoc_id, assoc_map)
      # else
      #   raise NotImplementedError
      end
    end

    def handle_removed_assoc(other_name, assoc_id, assoc_map)
      debug log_format_h("handle_removed_#{other_name}", assoc_id: assoc_id, assoc_map: assoc_map)

      case other_name
      when :datapath then handle_removed_datapath(assoc_id, assoc_map)
      when :network then handle_removed_network(assoc_id, assoc_map)
      when :segment then handle_removed_segment(assoc_id, assoc_map)
      # when :route_link then handle_removed_route_link(assoc_id, assoc_map)
      # else
      #   raise NotImplementedError
      end
    end

    def handle_added_datapath(assoc_id, assoc_map)
      raise NotImplementedError
    end
    alias :handle_added_network :handle_added_datapath
    alias :handle_added_segment :handle_added_datapath
    alias :handle_added_route_link :handle_added_datapath
    alias :handle_removed_datapath :handle_added_datapath
    alias :handle_removed_network :handle_added_datapath
    alias :handle_removed_segment :handle_added_datapath
    alias :handle_removed_route_link :handle_added_datapath
    alias :added_underlay_datapath :handle_added_datapath
    alias :removed_underlay_datapath :handle_added_datapath

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
