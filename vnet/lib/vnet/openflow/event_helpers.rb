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
  # Update item states:
  #

  # TODO: Move to the manager base directory.
  module UpdateItemStates

    # subscribe_event FOO_UPDATE_ITEM_STATES, :update_item_states

    def initialize(*args, &block)
      super
      @update_item_states = {}
    end

    private

    # Requires queue ':update_item_states'.
    def update_item_state(item)
      # Must be implemented by manager
      raise NotImplementedError
    end

    # Returns FOO_UPDATE_ITEM_STATES.
    def update_item_states_event
      # Must be implemented by manager
      raise NotImplementedError
    end

    def add_item_id_to_update_item_states(item_id)
      should_publish = @update_item_states.empty?
      @update_item_states[item_id] = true

      should_publish &&
        publish(update_item_states_event, id: :update_item_states)
    end

    def add_item_ids_to_update_item_states(item_ids)
      should_publish = @update_item_states.empty?

      item_ids.select { |item_id|
        @update_item_states[item_id].nil?
      }.each { |item_id|
        @update_item_states[item_id] = true
      }

      should_publish &&
        publish(update_item_states_event, id: :update_item_states)
    end

    # FOO_UPDATE_ITEM_STATES on queue ':update_item_states'
    def update_item_states(params)
      while !@update_item_states.empty?
        item_ids = @update_item_states.keys

        info log_format("updating item states", item_ids.to_s)

        item_ids.each { |item_id|
          next unless @update_item_states.delete(item_id)

          item = @items[item_id] || next
          next unless item.installed

          update_item_state(item)
        }

        # Sleep for 10 msec in order to poll up more potential changes
        # to the same items.
        sleep(0.01)
      end

    end

  end

  #
  # Update property states:
  #

  # TODO: Move to the manager base directory.
  module UpdatePropertyStates

    # subscribe_event FOO_UPDATE_PROPERTY_STATES, :update_property_states

    def initialize(*args, &block)
      super
      @update_property_states = {}
    end

    private

    # Requires queue 'property_type'.
    def update_property_state(property_type, property_id)
      # Must be implemented by manager
      raise NotImplementedError
    end

    # Returns FOO_UPDATE_PROPERTY_STATES.
    def update_property_states_event
      # Must be implemented by manager
      raise NotImplementedError
    end

    def add_property_id_to_update_property_states(property_type, property_id)
      update_states = (@update_property_states[property_type] ||= {})

      should_publish = update_states.empty?
      update_states[property_id] = true

      should_publish &&
        publish(update_property_states_event, id: property_type)
    end

    def add_property_ids_to_update_property_states(property_type, property_ids)
      update_states = (@update_property_states[property_type] ||= {})

      should_publish = update_states.empty?

      property_ids.select { |property_id|
        update_states[property_id].nil?
      }.each { |property_id|
        update_states[property_id] = true
      }

      should_publish &&
        publish(update_property_states_event, id: property_type)
    end

    # FOO_UPDATE_PROPERTY_STATES on queue 'property_type'.
    def update_property_states(params)
      property_type = params[:id] || return
      update_states = (@update_property_states[property_type] || return)

      while !update_states.empty?
        property_ids = update_states.keys

        info log_format("updating '#{property_type}' property states", property_ids.to_s)

        property_ids.each { |property_id|
          next unless update_states.delete(property_id)

          update_property_state(property_type, property_id)
        }

        # Sleep for 10 msec in order to poll up more potential changes
        # to the same propertys.
        sleep(0.01)
      end

    end

  end

end
