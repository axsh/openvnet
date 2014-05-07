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

    def activate_interface_query(state_id)
      { interface_id: state_id }
    end

    def activate_interface_match_proc(state_id)
      Proc.new { |id, item| item.interface_id == state_id }
    end

    # Return an 'update_item(item, state_id, params)' proc or nil.
    def activate_interface_update_item_proc(state_id, params)
      nil
    end

    # Return value must not be nil or false.
    def activate_interface_value(state_id, params)
      true
    end

    # FOO_ACTIVATE_INTERFACE on queue ':interface'
    def activate_interface(params)
      state_id = params[:interface_id] || return
      return if @active_interfaces.has_key? state_id

      value = activate_interface_value(state_id, params) || return
      @active_interfaces[state_id] = value

      activate_interface_update_item_proc(state_id, params).tap { |proc|
        next unless proc

        @items.select(&activate_interface_match_proc(state_id)).each(&proc)
      }

      internal_load_where(activate_interface_query(state_id))
    end

    # FOO_DEACTIVATE_INTERFACE on queue ':interface'
    def deactivate_interface(params)
      state_id = params[:interface_id] || return
      return unless @active_interfaces.delete(state_id)

      items = @items.select(&activate_interface_match_proc(state_id))

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

    def activate_network_query(state_id)
      { network_id: state_id }
    end

    def activate_network_match_proc(state_id)
      Proc.new { |id, item| item.network_id == state_id }
    end

    # Return an 'update_item(item, state_id, params)' proc or nil.
    def activate_network_update_item_proc(state_id, params)
      nil
    end

    # Return value must not be nil or false.
    def activate_network_value(state_id, params)
      true
    end

    # FOO_ACTIVATE_NETWORK on queue ':network'
    def activate_network(params)
      state_id = params[:network_id] || return
      return if @active_networks.has_key? state_id

      value = activate_network_value(state_id, params) || return
      @active_networks[state_id] = value

      activate_network_update_item_proc(state_id, params).tap { |proc|
        next unless proc

        @items.select(&activate_network_match_proc(state_id)).each(&proc)
      }

      internal_load_where(activate_network_query(state_id))
    end

    # FOO_DEACTIVATE_NETWORK on queue ':network'
    def deactivate_network(params)
      state_id = params[:network_id] || return
      return unless @active_networks.delete(state_id)

      items = @items.select(&activate_network_match_proc(state_id))

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

    def activate_route_link_query(state_id)
      { route_link_id: state_id }
    end

    def activate_route_link_match_proc(state_id)
      Proc.new { |id, item| item.route_link_id == state_id }
    end

    # Return an 'update_item(item, state_id, params)' proc or nil.
    def activate_route_link_update_item_proc(state_id, params)
      nil
    end

    # Return value must not be nil or false.
    def activate_route_link_value(state_id, params)
      true
    end

    # FOO_ACTIVATE_ROUTE_LINK on queue ':route_link'
    def activate_route_link(params)
      state_id = params[:route_link_id] || return
      return if @active_route_links.has_key? state_id

      value = activate_route_link_value(state_id, params) || return
      @active_route_links[state_id] = value

      activate_route_link_update_item_proc(state_id, params).tap { |proc|
        next unless proc

        @items.select(&activate_route_link_match_proc(state_id)).each(&proc)
      }

      internal_load_where(activate_route_link_query(state_id))
    end

    # FOO_DEACTIVATE_ROUTE_LINK on queue ':route_link'
    def deactivate_route_link(params)
      state_id = params[:route_link_id] || return
      return unless @active_route_links.delete(state_id)

      items = @items.select(&activate_route_link_match_proc(state_id))

      internal_unload_id_item_list(items)
    end

  end

end
