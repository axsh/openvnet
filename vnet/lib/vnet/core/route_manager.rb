# -*- coding: utf-8 -*-

module Vnet::Core

  class RouteManager < Vnet::Core::Manager
    include ActiveNetworkEvents
    include ActiveRouteLinkEvents

    #
    # Events:
    #

    subscribe_event ROUTE_INITIALIZED, :load_item
    subscribe_event ROUTE_UNLOAD_ITEM, :unload_item
    subscribe_event ROUTE_CREATED_ITEM, :created_item
    subscribe_event ROUTE_DELETED_ITEM, :unload_item

    subscribe_event ROUTE_ACTIVATE_NETWORK, :activate_network
    subscribe_event ROUTE_DEACTIVATE_NETWORK, :deactivate_network

    subscribe_event ROUTE_ACTIVATE_ROUTE_LINK, :activate_route_link
    subscribe_event ROUTE_DEACTIVATE_ROUTE_LINK, :deactivate_route_link

    #
    # Internal methods:
    #

    private

    #
    # Specialize Manager:
    #

    def mw_class
      MW::Route
    end

    def initialized_item_event
      ROUTE_INITIALIZED
    end

    def item_unload_event
      ROUTE_UNLOAD_ITEM
    end

    def match_item_proc_part(filter_part)
      filter, value = filter_part

      case filter
      when :id, :uuid, :interface_id, :network_id, :route_link_id, :egress, :ingress
        proc { |id, item| value == item.send(filter) }
      when :not_network_id
        proc { |id, item| value != item.network_id }
      else
        raise NotImplementedError, filter
      end
    end

    def query_filter_from_params(params)
      filter = []
      filter << {id: params[:id]} if params.has_key? :id
      filter << {interface_id: params[:interface_id]} if params.has_key? :interface_id
      filter << {network_id: params[:network_id]} if params.has_key? :network_id
      filter << {route_link_id: params[:route_link_id]} if params.has_key? :route_link_id
      filter
    end

    def item_initialize(item_map)
      item_class = Routes::Base

      item = item_class.new(dp_info: @dp_info, map: item_map)

      activate_network_pre_install(item.network_id, item)
      activate_route_link_pre_install(item.route_link_id, item)

      # While querying the database the active state of either network
      # or route link changed, so discard the item.
      return if !item.active_network && !item.active_route_link

      item
    end

    #
    # Create / Delete events:
    #

    def item_pre_install(item, item_map)
      case
      when !item.active_network && !item.active_route_link
        # The state changed since item_initialize so we skip install,
        # but don't delete it as the unload event should be in the
        # event queue.
        return
      when item.active_network && !item.active_route_link
        # TODO: Use event...
        @dp_info.router_manager.async.retrieve(id: item.route_link_id)
      end
    end

    def item_post_install(item, item_map)
      # TODO: Refactor...
      interface = @dp_info.interface_manager.retrieve(id: item.interface_id,
                                                      allowed_datapath_id: @datapath_info.id)

      if interface.nil?
        @dp_info.active_interface_manager.retrieve(interface_id: item.interface_id)
      end

      # TODO: Router egress is a property of the interface...(?)
      @dp_info.interface_manager.publish(Vnet::Event::INTERFACE_UPDATED,
                                         event: :enable_router_egress,
                                         id: item.interface_id)
    end
    
    def item_pre_uninstall(item)
      activate_network_pre_uninstall(item.network_id, item)
      activate_route_link_pre_uninstall(item.route_link_id, item)
    end

    # item created in db on queue 'item.id'
    def created_item(params)
      return if internal_detect_by_id(params)
      return if 
        @active_networks[params[:network_id]].nil? &&
        @active_route_links[params[:route_link_id]].nil?

      internal_new_item(mw_class.new(params))
    end

    #
    # Overload helper methods:
    #

    # We should only active networks on this datapath that have
    # non-simulated/remote interfaces.
    #
    # Note: Replace by active segment once implemented.

    def activate_network_value(state_id, params)
      {}
    end

    def activate_network_update_item_proc(state_id, value, params)
      Proc.new { |id, item|
        item.active_network = true
        value[item.id] = true
      }
    end

    def deactivate_network_update_item_proc(state_id, value, item)
      item.active_network = false
      value.delete(item.id)
    end

    def activate_route_link_value(state_id, params)
      {}
    end

    def activate_route_link_update_item_proc(state_id, value, params)
      Proc.new { |id, item|
        item.active_route_link = true
        value[item.id] = true
      }
    end

    def deactivate_route_link_update_item_proc(state_id, value, item)
      item.active_route_link = false
      value.delete(item.id)
    end

  end

end
