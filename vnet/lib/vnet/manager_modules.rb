# -*- coding: utf-8 -*-

module Vnet

  #
  # Update item states:
  #

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

    def add_item_id_to_update_queue(item_id)
      raise ArgumentError, 'item id of nil not allowed' if item_id.nil?

      should_publish = @update_item_states.empty?
      @update_item_states[item_id] = true

      should_publish &&
        publish(update_item_states_event, id: :update_item_states)
    end

    def add_item_ids_to_update_queue(item_ids)
      raise ArgumentError, 'item id of nil not allowed' if item_ids.index(nil)

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

    def add_property_id_to_update_queue(property_type, property_id)
      raise ArgumentError, 'property id of nil not allowed' if property_id.nil?

      update_states = (@update_property_states[property_type] ||= {})

      should_publish = update_states.empty?
      update_states[property_id] = true

      should_publish &&
        publish(update_property_states_event, id: property_type)
    end

    def add_property_ids_to_update_queue(property_type, property_ids)
      raise ArgumentError, 'property id of nil not allowed' if property_ids.index(nil)

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
