# -*- coding: utf-8 -*-

module Vnet::Openflow

  #
  # Active interfaces:
  #

  module ActiveInterfaces

    # subscribe_event FOO_ACTIVATE_INTERFACE, :activate_interface
    # subscribe_event FOO_DEACTIVATE_INTERFACE, :deactivate_interface

    def initialize(*args, &block)
      super
      @active_interfaces = {}
    end

    private

    def activate_interface_query(interface_id)
      { interface_id: interface_id }
    end

    def activate_interface_match_proc(interface_id)
      Proc.new { |id, item| item.interface_id == interface_id }
    end

    # Return an 'update_item(item, interface_id, params)' proc or nil.
    def activate_interface_update_item_proc(interface_id, params)
      nil
    end

    # Return value must not be nil or false.
    def activate_interface_value(interface_id, params)
      true
    end

    # FOO_ACTIVATE_INTERFACE on queue ':interface'
    def activate_interface(params)
      interface_id = params[:interface_id] || return
      return if @active_interfaces.has_key? params[:interface_id]

      value = activate_interface_value(interface_id, params) || return
      @active_interfaces[interface_id] = value

      activate_interface_update_item_proc(interface_id, params).tap { |proc|
        next unless proc

        @items.select(&activate_interface_match_proc(interface_id)).each(&proc)
      }

      internal_load_where(activate_interface_query(interface_id))
    end

    # FOO_DEACTIVATE_INTERFACE on queue ':interface'
    def deactivate_interface(params)
      interface_id = params[:interface_id] || return
      return unless @active_interfaces.delete(interface_id)

      items = @items.select(&activate_interface_match_proc(interface_id))

      internal_unload_id_item_list(items)
    end

  end

  #
  # Active networks:
  #

  module ActiveNetworks

    # subscribe_event FOO_ACTIVATE_NETWORK, :activate_network
    # subscribe_event FOO_DEACTIVATE_NETWORK, :deactivate_network

    def initialize(*args, &block)
      super
      @active_networks = {}
    end

    private

    def activate_network_query(network_id)
      { network_id: network_id }
    end

    def activate_network_match_proc(network_id)
      Proc.new { |id, item| item.network_id == network_id }
    end

    # Return an 'update_item(item, network_id, params)' proc or nil.
    def activate_network_update_item_proc(network_id, params)
      nil
    end

    # Return value must not be nil or false.
    def activate_network_value(network_id, params)
      true
    end

    # FOO_ACTIVATE_NETWORK on queue ':network'
    def activate_network(params)
      network_id = params[:network_id] || return
      return if @active_networks.has_key? params[:network_id]

      value = activate_network_value(network_id, params) || return
      @active_networks[network_id] = value

      activate_network_update_item_proc(network_id, params).tap { |proc|
        next unless proc

        @items.select(&activate_network_match_proc(network_id)).each(&proc)
      }

      internal_load_where(activate_network_query(network_id))
    end

    # FOO_DEACTIVATE_NETWORK on queue ':network'
    def deactivate_network(params)
      network_id = params[:network_id] || return
      return unless @active_networks.delete(network_id)

      items = @items.select(&activate_network_match_proc(network_id))

      internal_unload_id_item_list(items)
    end

  end

  #
  # Active route links:
  #

  module ActiveRouteLinks

    # subscribe_event FOO_ACTIVATE_ROUTE_LINK, :activate_route_link
    # subscribe_event FOO_DEACTIVATE_ROUTE_LINK, :deactivate_route_link

    def initialize(*args, &block)
      super
      @active_route_links = {}
    end

    private

    def activate_route_link_query(route_link_id)
      { route_link_id: route_link_id }
    end

    def activate_route_link_match_proc(route_link_id)
      Proc.new { |id, item| item.route_link_id == route_link_id }
    end

    # Return an 'update_item(item, route_link_id, params)' proc or nil.
    def activate_route_link_update_item_proc(route_link_id, params)
      nil
    end

    # Return value must not be nil or false.
    def activate_route_link_value(route_link_id, params)
      true
    end

    # FOO_ACTIVATE_ROUTE_LINK on queue ':route_link'
    def activate_route_link(params)
      route_link_id = params[:route_link_id] || return
      return if @active_route_links.has_key? params[:route_link_id]

      value = activate_route_link_value(route_link_id, params) || return
      @active_route_links[route_link_id] = value

      activate_route_link_update_item_proc(route_link_id, params).tap { |proc|
        next unless proc

        @items.select(&activate_route_link_match_proc(route_link_id)).each(&proc)
      }

      internal_load_where(activate_route_link_query(route_link_id))
    end

    # FOO_DEACTIVATE_ROUTE_LINK on queue ':route_link'
    def deactivate_route_link(params)
      route_link_id = params[:route_link_id] || return
      return unless @active_route_links.delete(route_link_id)

      items = @items.select(&activate_route_link_match_proc(route_link_id))

      internal_unload_id_item_list(items)
    end

  end

end
