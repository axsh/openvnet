# -*- coding: utf-8 -*-

require 'sequel/core'
require 'sequel/sql'

module Vnet

  class Manager
    include Celluloid
    include Celluloid::Logger
    include Vnet::Constants::Openflow
    include Vnet::Event::EventTasks
    include Vnet::Event::Notifications
    include Vnet::LookupParams

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

      @load_queries = {}
    end

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

    #
    # Polling methods:
    #

    def wait_for_initialized(max_wait = 10.0)
      internal_wait_for_initialized(max_wait)
    end

    def wait_for_loaded(params, max_wait = 10.0, try_load = false)
      item_to_hash(internal_wait_for_loaded(params, max_wait, try_load))
    end

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

    # TODO: Move to core/manager.
    def set_datapath_info(datapath_info)
      if @datapath_info
        raise("Manager.set_datapath_info called twice.")
      end

      if datapath_info.nil? || datapath_info.id.nil?
        raise("Manager.set_datapath_info received invalid datapath info.")
      end

      @datapath_info = datapath_info

      # We need to update remote interfaces in case they are now in
      # our datapath.
      initialized_datapath_info
      nil
    end

    def start_initialize
      if @state != :uninitialized
        raise("Manager.start_initialized must be called on an uninitialized manager.")
      end

      do_initialize

      @state = :initialized

      # TODO: Catch errors and return nil when do_initialize fails.
      resume_event_tasks(:initialized, true)
      nil
    end

    def do_initialize
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      (@log_prefix || "") + message + (values ? " (#{values})" : '')
    end

    def log_format_h(message, values)
      str = values && values.map { |value|
        value.join(':')
      }.join(' ')

      log_format(message, str)
    end

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
    # Filters:
    #

    # We explicity initialize each proc parts into the method's local
    # context, and create the block by referencing those for
    # optimization reasons.
    #
    # Properly verify the speed of any changes to the implementation.

    def match_item_proc(params)
      case params.size
      when 1
        part_1 = params.to_a.first
        match_item_proc_part(part_1)
      when 2
        part_1, part_2 = params.to_a
        part_1 = match_item_proc_part(part_1)
        part_2 = match_item_proc_part(part_2)
        part_1 && part_2 &&
          proc { |id, item|
          part_1.call(id, item) &&
          part_2.call(id, item)
        }
      when 3
        part_1, part_2, part_3 = params.to_a
        part_1 = match_item_proc_part(part_1)
        part_2 = match_item_proc_part(part_2)
        part_3 = match_item_proc_part(part_3)
        part_1 && part_2 && part_3 &&
          proc { |id, item|
          part_1.call(id, item) &&
          part_2.call(id, item) &&
          part_3.call(id, item)
        }
      when 4
        part_1, part_2, part_3, part_4 = params.to_a
        part_1 = match_item_proc_part(part_1)
        part_2 = match_item_proc_part(part_2)
        part_3 = match_item_proc_part(part_3)
        part_4 = match_item_proc_part(part_4)
        part_1 && part_2 && part_3 && part_4 &&
          proc { |id, item|
          part_1.call(id, item) &&
          part_2.call(id, item) &&
          part_3.call(id, item) &&
          part_4.call(id, item)
        }
      when 0
        proc { |id, item| true }
      else
        raise NotImplementedError, params.inspect
      end
    end

    def match_item_proc_part(filter_part)
      raise NotImplementedError, params.inspect
    end

    def select_filter_from_params(params)
      return nil if params.has_key?(:uuid) && params[:uuid].nil?

      create_batch(mw_class.batch, params[:uuid], query_filter_from_params(params))
    end

    # Creates a batch object for querying a set of item to load,
    # excluding the 'uuid' parameter.
    def query_filter_from_params(params)
      # Must be implemented by subclass
      raise NotImplementedError
    end

    def create_batch(batch, uuid, filters)
      expression = (filters.size > 1) ? Sequel.&(*filters) : filters.first

      return unless expression || uuid

      dataset = uuid ? batch.dataset_where_uuid(uuid) : batch.dataset
      dataset = expression ? dataset.where(expression) : dataset
    end

    #
    # Item-related methods:
    #

    def item_to_hash(item)
      item && item.to_hash
    end

    def internal_retrieve(params)
      item = internal_detect(params)
      return item if item

      if @load_queries.has_key?(params)
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
      @load_queries[params] = :querying

      item = nil
      select_filter = select_filter_from_params(params) || return
      item_map = select_item(select_filter.first) || return

      # TODO: Only allow one fiber at the time to make a request with
      # the exact same select_filter. The remaining fibers should use
      # internal_wait_for_loaded/initializing.

      item = internal_new_item(item_map)

      # TODO: Set querying to something else?

      item

    ensure
      # TODO: Ensure should only include the fiber that does the query.

      # We can assume that the load failed if item is nil, and such
      # there will be no trigger of event tasks once the item is
      # initialized.
      #
      # Therefor we use event task to pass a nil value to the waiting
      # tasks that have the same query params.

      @load_queries.delete(params)

      # TODO: Should we make sure no event tasks are left with
      # 'params' task_id?
      resume_event_tasks(:retrieved, item)

      if item.nil?
        info log_format_h("internal_retrieve main fiber query FAILED", params && params.to_h)
      end
    end

    # The default select call with no fill options.
    def select_item(batch)
      batch.commit
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
    # Internal polling methods:
    #

    def internal_wait_for_initialized(max_wait)
      if @state == :initialized
        return
      end

      # TODO: Check for invalid state, cleaned up, etc.
      create_event_task(:initialized, max_wait) { |result|
        true
      }
    end

    # TODO: Wait_for_loaded needs to work correctly when create is
    # called and the manager doesn't know the item is wanted.

    def internal_wait_for_loaded(params, max_wait, try_load)
      item = internal_detect_loaded(params)
      return item if item

      if try_load
        # TODO: internal_retrieve does not have max_wait or immediate
        # return if in retrieve queue.
        self.async.retrieve(params)

        item = internal_detect_loaded(params)
        return item if item

        # TODO: Check if the item is uninstalling, or other edge cases. (?)
      end

      create_event_task_match_proc(:loaded, params, max_wait)
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
