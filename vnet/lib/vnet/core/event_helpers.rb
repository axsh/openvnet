# -*- coding: utf-8 -*-

module Vnet::Core

  #
  # Active interfaces:
  #

  module ActiveInterfaceEvents

    # subscribe_event FOO_ACTIVATE_INTERFACE, :activate_interface
    # subscribe_event FOO_DEACTIVATE_INTERFACE, :deactivate_interface

    def initialize(*args, &block)
      super
      @active_interfaces = {}
    end

    private

    def activate_interface_query(state_id, params)
      { interface_id: state_id }
    end

    def activate_interface_match_proc(state_id, params)
      Proc.new { |id, item| item.interface_id == state_id }
    end

    # Return an 'update_item(item, state_id, params)' proc or nil.
    def activate_interface_update_item_proc(state_id, value, params)
      nil
    end

    # Return value must not be nil or false.
    def activate_interface_value(state_id, params)
      true
    end

    def activate_interface_pre_install(state_id, item)
      value = @active_interfaces[state_id] || return
      
      activate_interface_update_item_proc(state_id, value, {}).tap { |proc|
        proc && proc.call(item.id, item)
      }
    end

    def activate_interface_pre_uninstall(state_id, item)
      value = @active_interfaces[state_id] || return
      deactivate_interface_update_item_proc(state_id, value, item)
    end

    # FOO_ACTIVATE_INTERFACE on queue ':interface'
    def activate_interface(params)
      state_id = params[:interface_id] || return
      return if @active_interfaces.has_key? state_id

      value = activate_interface_value(state_id, params) || return
      @active_interfaces[state_id] = value

      activate_interface_update_item_proc(state_id, value, params).tap { |proc|
        next unless proc

        @items.select(&activate_interface_match_proc(state_id, params)).each(&proc)
      }

      internal_load_where(activate_interface_query(state_id, params))
    end

    # FOO_DEACTIVATE_INTERFACE on queue ':interface'
    def deactivate_interface(params)
      state_id = params[:interface_id] || return
      return unless @active_interfaces.delete(state_id)

      items = @items.select(&activate_interface_match_proc(state_id, params))

      internal_unload_id_item_list(items)
    end

  end

  #
  # Active networks:
  #

  module ActiveNetworkEvents

    # subscribe_event FOO_ACTIVATE_NETWORK, :activate_network
    # subscribe_event FOO_DEACTIVATE_NETWORK, :deactivate_network

    def initialize(*args, &block)
      super
      @active_networks = {}
    end

    private

    def activate_network_query(state_id, params)
      { network_id: state_id }
    end

    def activate_network_match_proc(state_id, params)
      Proc.new { |id, item| item.network_id == state_id }
    end

    # Return an 'update_item(item, state_id, params)' proc or nil.
    def activate_network_update_item_proc(state_id, value, params)
      nil
    end

    # Return value must not be nil or false.
    def activate_network_value(state_id, params)
      true
    end

    def activate_network_pre_install(state_id, item)
      value = @active_networks[state_id] || return
      
      activate_network_update_item_proc(state_id, value, {}).tap { |proc|
        proc && proc.call(item.id, item)
      }
    end

    def activate_network_pre_uninstall(state_id, item)
      value = @active_networks[state_id] || return
      deactivate_network_update_item_proc(state_id, value, item)
    end

    # FOO_ACTIVATE_NETWORK on queue ':network'
    def activate_network(params)
      state_id = params[:network_id] || return
      return if @active_networks.has_key? state_id

      value = activate_network_value(state_id, params) || return
      @active_networks[state_id] = value

      activate_network_update_item_proc(state_id, value, params).tap { |proc|
        next unless proc

        @items.select(&activate_network_match_proc(state_id, params)).each(&proc)
      }

      internal_load_where(activate_network_query(state_id, params))
    end

    # FOO_DEACTIVATE_NETWORK on queue ':network'
    def deactivate_network(params)
      state_id = params[:network_id] || return
      return unless @active_networks.delete(state_id)

      items = @items.select(&activate_network_match_proc(state_id, params))

      internal_unload_id_item_list(items)
    end

  end

  #
  # Active ports:
  #

  module ActivePortEvents

    # subscribe_event FOO_ACTIVATE_PORT, :activate_port
    # subscribe_event FOO_DEACTIVATE_PORT, :deactivate_port

    def initialize(*args, &block)
      super
      @active_ports = {}
    end

    private

    def activate_port_query(state_id, params)
      { port_name: params[:port_name] }
    end

    def activate_port_match_proc(state_id, params)
      port_name = params[:port_name]

      Proc.new { |id, item|
        item.port_name == port_name
      }
    end

    # Return an 'update_item(item, state_id, params)' proc or nil.
    def activate_port_update_item_proc(state_id, value, params)
      nil
    end

    # Return value must not be nil or false.
    def activate_port_value(state_id, params)
      true
    end

    def activate_port_pre_install(state_id, item)
      value = @active_ports[state_id] || return
      
      activate_port_update_item_proc(state_id, value, {}).tap { |proc|
        proc && proc.call(item.id, item)
      }
    end

    def activate_port_pre_uninstall(state_id, item)
      value = @active_ports[state_id] || return
      deactivate_port_update_item_proc(state_id, value, item)
    end

    # FOO_ACTIVATE_PORT on queue ':port'
    def activate_port(params)
      state_id = params[:port_number] || return
      return if @active_ports.has_key? state_id

      value = activate_port_value(state_id, params) || return
      @active_ports[state_id] = value

      activate_port_update_item_proc(state_id, value, params).tap { |proc|
        next unless proc

        @items.select(&activate_port_match_proc(state_id, params)).each(&proc)
      }

      internal_load_where(activate_port_query(state_id, params))
    end

    # FOO_DEACTIVATE_PORT on queue ':port'
    def deactivate_port(params)
      state_id = params[:port_number] || return
      return unless @active_ports.delete(state_id)

      items = @items.select(&activate_port_match_proc(state_id, params))

      internal_unload_id_item_list(items)
    end

  end

  #
  # Active route links:
  #

  module ActiveRouteLinkEvents

    # subscribe_event FOO_ACTIVATE_ROUTE_LINK, :activate_route_link
    # subscribe_event FOO_DEACTIVATE_ROUTE_LINK, :deactivate_route_link

    def initialize(*args, &block)
      super
      @active_route_links = {}
    end

    private

    def activate_route_link_query(state_id, params)
      { route_link_id: state_id }
    end

    def activate_route_link_match_proc(state_id, params)
      Proc.new { |id, item| item.route_link_id == state_id }
    end

    # Return an 'update_item(item, state_id, params)' proc or nil.
    def activate_route_link_update_item_proc(state_id, value, params)
      nil
    end

    # Return value must not be nil or false.
    def activate_route_link_value(state_id, params)
      true
    end

    def activate_route_link_pre_install(state_id, item)
      value = @active_route_links[state_id] || return
      
      activate_route_link_update_item_proc(state_id, value, {}).tap { |proc|
        proc && proc.call(item.id, item)
      }
    end

    def activate_route_link_pre_uninstall(state_id, item)
      value = @active_route_links[state_id] || return
      deactivate_route_link_update_item_proc(state_id, value, item)
    end

    # FOO_ACTIVATE_ROUTE_LINK on queue ':route_link'
    def activate_route_link(params)
      state_id = params[:route_link_id] || return
      return if @active_route_links.has_key? state_id

      value = activate_route_link_value(state_id, params) || return
      @active_route_links[state_id] = value

      activate_route_link_update_item_proc(state_id, value, params).tap { |proc|
        next unless proc

        @items.select(&activate_route_link_match_proc(state_id, params)).each(&proc)
      }

      internal_load_where(activate_route_link_query(state_id, params))
    end

    # FOO_DEACTIVATE_ROUTE_LINK on queue ':route_link'
    def deactivate_route_link(params)
      state_id = params[:route_link_id] || return
      return unless @active_route_links.delete(state_id)

      items = @items.select(&activate_route_link_match_proc(state_id, params))

      internal_unload_id_item_list(items)
    end

  end

end
