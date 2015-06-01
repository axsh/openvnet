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
      @items = {}
      @messages = {}
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

    def wait_for_loaded(params, max_wait = 10.0)
      item_to_hash(internal_wait_for_loaded(params))
    end
    
    def wait_for_unloaded(params, max_wait = 10.0)
      internal_wait_for_unloaded(params)
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
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      (@log_prefix || "") + message + (values ? " (#{values})" : '')
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

      select_filter = select_filter_from_params(params) || return
      item_map = select_item(select_filter.first) || return

      # TODO: Only allow one fiber at the time to make a request with
      # the exact same select_filter. The remaining fibers should use
      # internal_wait_for_loaded/initializing.

      internal_new_item(item_map)
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
      item_map = params[:item_map] || return
      item_id = item_map.id || return
      item = @items[item_id] || return

      debug log_format("installing " + item.pretty_id, item.pretty_properties)

      item_pre_install(item, item_map)
      item.try_install

      if item.invalid?
        debug log_format("installation failed, marked invalid " + item.pretty_id, item.pretty_properties)
        # TODO: Do some more cleanup here.
        return
      end

      item_post_install(item, item_map)

      resume_event_tasks(:loaded, item_id)
    end

    def unload_item(params)
      item_id = (params && params[:id]) || return
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
    # TODO: Remove 'params'
    def internal_new_item(item_map)
      item_id = item_map.id || return
      item = @items[item_id]
      return item if item

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
      return if params.empty?

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

    def internal_detect(params)
      if params.size == 1 && params.first.first == :id
        @items[params.first.last]
      else
        item = @items.detect(&match_item_proc(params))
        item && item.last
      end
    end

    def internal_detect_by_id(params)
      item_id = (params && params[:id]) || return
      @items[item_id]
    end

    def internal_detect_by_id_with_error(params)
      item_id = (params && params[:id])

      if item_id.nil?
        log_format("missing id")
        return
      end

      item = @items[item_id]

      if item.nil?
        log_format("missing item", "id:#{item_id}")
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

    def internal_wait_for_loaded(params, max_wait = 10.0)
      # TODO: Check if item was install and not being uninstalled.
      item = internal_detect(params)
      return item if item

      match_proc = match_item_proc(params)

      create_event_task(:loaded, max_wait) { |item_id|
        item = (item_id && @items[item_id]) || next
        match_proc.call(item_id, item) ? item : nil
      }
    end

    def internal_wait_for_unloaded(params, max_wait = 10.0)
      item = internal_detect(params)
      return true if item.nil?

      match_item_id = item.id

      create_event_task(:unloaded, max_wait) { |item_id|
        (item_id == match_item_id) ? true : nil
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
