# -*- coding: utf-8 -*-

require 'sequel/core'
require 'sequel/sql'

require 'vnet/manager_logger'
require 'vnet/manager_query'

module Vnet
  class Manager
    include Celluloid
    include Celluloid::Logger

    include Vnet::Constants::Openflow
    include Vnet::Event::EventTasks
    include Vnet::Event::Notifications
    include Vnet::Manager::Logger
    include Vnet::Manager::Query
    include Vnet::Params

    finalizer :start_cleanup

    # Main events:
    #
    # Manager and model events are separate as the manager events are
    # local and for the current manager only, while the model events
    # are global.
    #
    # Avoid duplicate manager event names.
    #
    # subscribe_event <MANAGER>_INITIALIZED, :load_item
    # subscribe_event <MANAGER>_UNLOAD_ITEM, :unload_item
    # subscribe_event <MODEL>_CREATED_ITEM, :created_item
    # subscribe_event <MODEL>_DELETED_ITEM, :unload_item
    #
    # Consistency:
    #
    # All events should have the item id "{id: item.id}" or a symbol
    # "{id: :foobar}" set to ensure exclusive execution of events for
    # said event or symbol.
    #
    # The id should be considered similar to a copy-on-write barrier,
    # as such the items can be read at any time by any fiber. Thus no
    # yielding or blocking operations can be done while the item is in
    # an inconsistent state.
    #
    # E.g. updating a set of variables or lists that depend on each
    # other will need to be done with no database requests, logging,
    # etc between the first and last update.
    #
    # Updating anything that is covered by another id or symbol lock
    # requires the use of local events.

    def initialize(info, options = {})
      @state = :uninitialized

      @items = {}
      @messages = {}

      init_query
    end

    # TODO: Depricate, and create a method that ensures the item is
    # fully loaded before returning.
    def retrieve(params)
      begin
        item_to_hash(internal_retrieve(params))
      rescue Celluloid::Task::TerminatedError => e
        raise e
      rescue Exception => e
        info log_format(e.message, e.class.name)
        e.backtrace.each { |str| info log_format(str) }
        raise e
      end
    end

    # TODO: Deprecate:
    def unload(params)
      item = internal_detect(params)
      return nil if item.nil?

      item_hash = item_to_hash(item)
      delete_item(item)
      item_hash
    end

    #
    # Enumerator methods:
    #

    def detect(params)
      item_to_hash(internal_detect(params))
    end

    def select(params = {})
      begin
        @items.select(&match_item_proc(params)).map { |id, item|
          item_to_hash(item)
        }
      rescue Celluloid::Task::TerminatedError => e
        raise e
      rescue Exception => e
        info log_format(e.message, e.class.name)
        e.backtrace.each { |str| info log_format(str) }
        raise e
      end
    end

    def load_first(params)
      item_to_hash(internal_load_first(params))
    end

    #
    # Polling methods:
    #

    # Returns true if initialized within 'max_wait' timeout, nil
    # otherwise.
    def wait_for_initialized(max_wait = 10.0)
      internal_wait_for_initialized(max_wait)
    end

    # Returns true if terminated within 'max_wait' timeout, nil
    # otherwise.
    def wait_for_terminated(max_wait = 10.0)
      internal_wait_for_terminated(max_wait)
    end

    # Returns item if loaded, nil otherwise.
    #
    # If the item is created while waiting the created_item subscriber
    # method is responsible for loading the item.
    def wait_for_loaded(params, max_wait = 10.0, try_load = false)
      # TODO: Deprecate try_load, use load_detect.
      item_to_hash(internal_wait_for_loaded(params, max_wait, try_load))
    end

    # Returns true if unloaded, nil otherwise.
    def wait_for_unloaded(params, max_wait = 10.0)
      internal_wait_for_unloaded(params, max_wait)
    end

    #
    # Other:
    #

    def packet_in(message)
      if (message.cookie & COOKIE_DYNAMIC_LOAD_MASK) == COOKIE_DYNAMIC_LOAD_MASK
        handle_dynamic_load(id: message.match.metadata & METADATA_VALUE_MASK,
                            message: message)
      else
        item = @items[message.cookie & COOKIE_ID_MASK]
        item.packet_in(message) if item
      end

      nil
    end

    def start_initialize
      if @state != :uninitialized
        raise "Manager.start_initialized must be called on an uninitialized manager."
      end

      @state = :initializing

      do_register_watchdog
      do_initialize

      @state = :initialized

      # TODO: Catch errors and return nil when do_initialize fails.
      resume_event_tasks(:initialized, true)
      nil
    end

    def start_cleanup
      case @state
      when :terminated, :uninitialized
        return
      when :cleanup
        return
      when :initializing
      when :initialized
      else
        raise "Manager.start_cleanup has invalid state: #{@state}."
      end

      if @state == :initialized
        @state = :cleanup
        do_cleanup
      end

      # TODO: Protect watchdog from dead actor.
      do_unregister_watchdog

      @state = :terminated

      resume_event_tasks(:terminated, true)
      nil
    end

    def do_register_watchdog
    end

    def do_unregister_watchdog
    end

    def do_initialize
    end

    def do_cleanup
    end

    #
    # Internal methods:
    #

    private

    #
    # Override these method to support additional parameters.
    #

    def mw_class
      # Must be implemented by subclass
      raise NotImplementedError
    end

    def item_initialize(item_map)
      # Must be implemented by subclass
      raise NotImplementedError
    end

    def initialized_item_event
      # Must be implemented by subclass
      raise NotImplementedError
    end

    def item_unload_event
      # Must be implemented by subclass
      raise NotImplementedError
    end

    def initialized_datapath_info
    end

    def cleared_datapath_info
    end

    def do_initialize
    end

    #
    # Item-related methods:
    #

    def item_to_hash(item)
      item && item.to_hash
    end

    # TODO: This should not return unloaded items!!!
    # TODO: Look into :retrieved.
    def internal_retrieve(params)
      item = internal_detect(params)
      return item if item

      if has_query?(params)
        item = create_event_task_match_proc(:retrieved, params, nil)

        if item.nil?
          info log_format_h("internal_retrieve duplicate fiber query FAILED", params)
          return
        end

        info log_format_h("internal_retrieve duplicate fiber query SUCCESS", params)

        return item
      end

      internal_retrieve_query_db(params)
    end

    def internal_retrieve_query_db(params)
      if internal_detect(params)
        raise "Manager.internal_retrieve_query_db internal_detect(params) must be nil."
      end

      # TODO: This overwrites load_queries, make this handle multiple queries.

      # TODO: This should not start another query while loading is
      # being done, only delete load_queries once loading is done.

      begin
        item = nil

        start_query(params) { |item_map|
          return if item_map.nil?

          item = internal_new_item(item_map)

          # TODO: Set querying to something else?
          # TODO: Expand load_queries to handle :loading state.

          return item
        }
      ensure
        # TODO: Ensure should only include the fiber that does the query.

        # We can assume that the load failed if item is nil, and such
        # there will be no trigger of event tasks once the item is
        # initialized.
        #
        # Therefor we use event task to pass a nil value to the waiting
        # tasks that have the same query params.

        # TODO: Should we make sure no event tasks are left with
        # 'params' task_id?
        resume_event_tasks(:retrieved, item)

        if item.nil?
          info log_format_h("internal_retrieve main fiber query FAILED", params && params.to_h)
        end
      end
    end

    #
    # Default install/uninstall methods:
    #

    def item_pre_install(item, item_map)
    end

    def item_post_install(item, item_map)
    end

    def item_pre_uninstall(item)
    end

    def item_post_uninstall(item)
    end

    def load_item(params)
      item_id = params[:id]
      item_map = params[:item_map]

      if item_id.nil?
        warn log_format_h("load_item requires a valid id", params && params.to_h)
        return
      end

      if item_map.nil?
        warn log_format_h("load_item requires a valid item_map", params && params.to_h)
        return
      end

      if item_map.id != item_id
        warn log_format_h("load_item requires id to match item_map.id", params && params.to_h)
        return
      end

      item = @items[item_id]

      # It should not be possible for the item to have disappeared due
      # to the event queue item id lock.
      if item.nil?
        warn log_format_h("load_item could not find item", params && params.to_h)
        return
      end

      debug log_format("installing " + item.pretty_id, item.pretty_properties)

      item_pre_install(item, item_map)
      item.try_install

      if item.invalid?
        warn log_format("installation failed, marked invalid " + item.pretty_id, item.pretty_properties)
        # TODO: Do some more cleanup here.
        return
      end

      item_post_install(item, item_map)

      # TODO: Consider checking if all task_id's are gone.

      item.set_loaded
      resume_event_tasks(:loaded, item)
    end

    def unload_item(params)
      item_id = (params && params[:id])

      if item_id.nil?
        warn log_format_h("unload_item requires a valid id", params && params.to_h)
        return
      end

      item = @items.delete(item_id) || return

      debug log_format("uninstalling " + item.pretty_id, item.pretty_properties)

      item_pre_uninstall(item)
      item.try_uninstall
      item_post_uninstall(item)

      resume_event_tasks(:unloaded, item_id)
    end

    #
    # Internal methods:
    #

    # Creates a new item based from a sequel object. For use
    # internally and by 'created_item' specialization method.
    #
    # TODO: Rename internal_load_item
    # TODO: Create a default 'created_item' method.
    def internal_new_item(item_map)
      item_id = item_map.id

      if item_id.nil?
        warn log_format_h("internal_new_item requires a valid item_map.id", item_map && item_map.to_h)
        return
      end

      return @items[item_id] if @items[item_id]

      item_initialize(item_map).tap do |item|
        # TODO: Delete item from items if returned nil.
        return unless item
        @items[item_map.id] = item
        publish(initialized_item_event,
                id: item_map.id,
                item_map: item_map)
      end
    end

    def internal_unload_id_item_list(items)
      items.each { |item_id,item|
        publish(item_unload_event, id: item_id)
      }
    end

    # TODO: Use an array of deleted item id's from events, which will
    # only be called once this method completes. Concurrent load
    # messages should use a counter to know when it is safe to clear
    # the list of deleted item id's.

    # Load all items that match the supplied query parameter
    def internal_load_where(params)
      if params.empty?
        warn log_format("internal_load_where does not allow empty params")
        return
      end

      filter = query_filter_from_params(params) || return
      expression = ((filter.size > 1) ? Sequel.&(*filter) : filter.first) || return

      item_maps = select_item(mw_class.batch.where(filter).all) || return
      item_maps.each { |item_map| internal_new_item(item_map) }
    end

    # TODO: Create an internal delete item method that 'delete item'
    # events are not missed if they happen between a select query and
    # an initialize_item event.

    #
    # Internal enumerators:
    #

    # Make into a module.

    def internal_detect(params)
      if params.size == 1 && params.first.first == :id
        @items[params.first.last]
      else
        item = @items.detect(&match_item_proc(params))
        item && item.last
      end
    end

    def internal_detect_loaded(params)
      item = internal_detect(params)
      (item && item.loaded?) ? item : nil
    end

    def internal_detect_by_id(params)
      item_id = (params && params[:id])

      if item_id.nil?
        warn log_format_h("internal_detect_by_id requires a valid id", params && params.to_h)
        return
      end

      @items[item_id]
    end

    # TODO: Reconsider changing the level of logging.
    def internal_detect_by_id_with_error(params)
      item_id = (params && params[:id])

      if item_id.nil?
        warn log_format("missing id")
        return
      end

      item = @items[item_id]

      if item.nil?
        warn log_format("missing item", "id:#{item_id}")
        return
      end

      item
    end

    def internal_select(params)
      @items.select(&match_item_proc(params))
    end

    #
    # Internal load/unload methods::
    #

    def internal_load_first(params)
      item = internal_detect(params)
      return item if item && item.loaded?

      if item.nil? && !has_query?(params)
        internal_retrieve_query_db(params)
      end

      return
    end

    #
    # Internal polling methods:
    #

    def internal_wait_for_initialized(max_wait)
      if @state == :initialized
        return true
      end

      # TODO: Check for invalid state, cleaned up, etc.
      create_event_task(:initialized, max_wait) { |result|
        true
      }
    end

    def internal_wait_for_terminated(max_wait)
      if @state == :terminated
        return true
      end

      # TODO: Check for invalid state, cleaned up, etc.
      create_event_task(:terminated, max_wait) { |result|
        true
      }
    end

    # TODO: Wait_for_loaded needs to work correctly when create is
    # called and the manager doesn't know the item is wanted.

    # TODO: wait_for_loaded doesn't work correctly if created_item
    # does not load the item.

    def internal_wait_for_loaded(params, max_wait, try_load)
      task_init = proc {
        item = internal_detect_loaded(params)
        return item if item

        if try_load
          # TODO: If retrieve fails we're not retrying, it relies on
          # created_item event being sent. Change this to instead be
          # handled with task_init.

          # - check load_queries for params.
          # - check is loading

          # If retrieve fails due to item not existing we rely on
          # created_item event load item.
          #
          # TODO: Verify that created_item actually loads the item.

          # TODO: Use internal methods for this.
          self.async.load_first(params)

          # TODO: Verify that we are loading. (?)
          # TODO: Check if the item is uninstalling, or other edge cases. (?)
          item = internal_detect_loaded(params)
          return item if item
        end
      }

      create_event_task_match_proc(:loaded, params, max_wait, task_init)
    end

    def internal_wait_for_unloaded(params, max_wait)
      item = internal_detect(params)
      return true if item.nil?

      match_item_id = item.id

      create_event_task(:unloaded, max_wait) { |item_id|
        (item_id == match_item_id) ? true : nil
      }
    end

    def create_event_task_match_proc(task_name, params, max_wait, task_init = nil)
      match_proc = match_item_proc(params)

      create_event_task(task_name, max_wait, params, task_init) { |item|
        (item && match_proc.call(item.id, item)) ? item : nil
      }
    end

    #
    # Packet handling:
    #

    # TODO: Move to a module.

    def handle_dynamic_load(params)
      item_id = params[:id]

      debug log_format('handle dynamic load of item', "id: #{item_id}")

      return if !push_message(item_id, params[:message])

      item = internal_retrieve(id: item_id)
      return if item.nil?

      return item
    end

    # Returns true if the message queue was empty for 'item_id'.
    def push_message(item_id, message)
      return if item_id.nil? || item_id <= 0
      return if message.nil?

      # Check if the item got loaded already. Currently we just drop
      # the packets to avoid packets being reflected back to the
      # controller.
      return if @items[item_id]

      if @messages.has_key? item_id
        # TODO: Cull the message queue if above a certain size.
        @messages[item_id] << {
          :message => message,
          :timestamp => Time.now
        }

        return false
      end

      @messages[item_id] = [{ :message => message,
                              :timestamp => Time.now
                            }]
      true
    end
  end
end
