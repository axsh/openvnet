# -*- coding: utf-8 -*-

module Vnet::Openflow

  #
  # Active interface:
  #

  module ActiveInterface

    # subscribe_event FOO_ACTIVATE_INTERFACE, :activate_interface
    # subscribe_event FOO_DEACTIVATE_INTERFACE, :deactivate_interface

    def initialize(*args, &block)
      super
      @active_interfaces = {}
    end

    private

    # Return value must not be nil or false.
    def activate_interface_value(interface_id)
      true
    end

    def activate_interface_query(interface_id)
      { interface_id: interface_id }
    end

    def activate_interface_match_proc(interface_id)
      Proc.new { |id, item| item.interface_id == interface_id }
    end

    # FOO_ACTIVATE_INTERFACE on queue ':interface'
    def activate_interface(params)
      interface_id = params[:interface_id] || return
      return if @active_interfaces.has_key? params[:interface_id]

      @active_interfaces[interface_id] = activate_interface_value(interface_id)

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

end
