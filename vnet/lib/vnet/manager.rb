# -*- coding: utf-8 -*-

require 'sequel/core'
require 'sequel/sql'

module Vnet

  class Manager
    include Celluloid
    include Celluloid::Logger
    include Vnet::Constants::Openflow
    include Vnet::Event::Notifications

    # MW_CLASS = MW::Foo

    def initialize(dp_info)
      @dp_info = dp_info

      @datapath_info = nil
      @items = {}
      @messages = {}

      @log_prefix = "#{@dp_info.try(:dpid_s)} #{self.class.name.to_s.demodulize.underscore}: "
    end

    def retrieve(params)
      begin
        item_to_hash(item_by_params(params))
      rescue Celluloid::Task::TerminatedError => e
        raise e
      rescue Exception => e
        info log_format(e.message, e.class.name)
        e.backtrace.each { |str| info log_format(str) }
        raise e
      end
    end
    alias_method :item, :retrieve

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
        @items.select { |id, item|
          match_item?(item, params)
        }.map { |id, item|
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

      @datapath_info = datapath_info

      # We need to update remote interfaces in case they are now in
      # our datapath.
    end

    #
    # Internal methods:
    #

    private

    # Little shortcut method
    def is_remote?(owner_datapath_id, active_datapath_id = nil)
      @datapath_info.is_remote?(owner_datapath_id, active_datapath_id)
    end

    def log_format(message, values = nil)
      @log_prefix + message + (values ? " (#{values})" : '')
    end

    #
    # Override these method to support additional parameters.
    #

    def mw_class
      # Must be implemented by subclass
      raise NotImplementedError
    end

    def item_initialize(item_map, params)
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

    # Optimize this by returning a proc block.
    def match_item?(item, params)
      return false if params[:id] && params[:id] != item.id
      return false if params[:uuid] && params[:uuid] != item.uuid
      true
    end

    # TODO: Cleanup...
    def select_filter_from_params(params)
      case
      when params[:id]   then {:id => params[:id]}
      when params[:uuid] then params[:uuid]
      else
        # Any invalid params that should cause an exception needs to
        # be caught by the item_by_params_direct method.
        return nil
      end
    end

    # Creates a batch object for querying a set of item to load,
    # excluding the 'uuid' parameter.
    def query_filter_from_params(params)
      # Must be implemented by subclass
      raise NotImplementedError
    end

    def create_batch(batch, uuid, filters)
      expression = (filters.size > 1) ? Sequel.&(*filters) : filters.first

      if expression
        uuid ? batch[uuid].where(expression) : batch.dataset.where(expression).first
      else
        uuid ? batch[uuid] : nil
      end
    end

    #
    # Item-related methods:
    #

    def item_to_hash(item)
      item && item.to_hash
    end

    def item_by_params(params)
      if params[:reinitialize] != true
        item = internal_detect(params)

        if item || params[:dynamic_load] == false
          return item
        end
      end

      select_filter = select_filter_from_params(params) || return
      item_map = select_item(select_filter) || return

      if params[:reinitialize] == true
        @items.delete(item_map.id)
      end

      internal_new_item(item_map, params)
    end

    # The default select call with no fill options.
    def select_item(batch)
      batch.commit
    end

    # The default install item call.
    #
    # FOO_INITIALIZED on queue 'item.id'.
    def install_item(params)
      item_map = params[:item_map] || return
      item = (item_map.id && @items[item_map.id]) || return

      debug log_format("install " + item.pretty_id, item.pretty_properties)

      item_pre_install(item, item_map)
      item.try_install
      item_post_install(item, item_map)
    end

    def item_pre_install(item, item_map)
    end

    def item_post_install(item, item_map)
    end

    #
    # Internal methods:
    #

    # Creates a new item based from a sequel object. For use
    # internally and by 'created_item' specialization method.
    #
    # TODO: Rename internal_load_item
    def internal_new_item(item_map, params)
      item = @items[item_map.id]
      return item if item

      item_initialize(item_map, params).tap do |item|
        return unless item
        @items[item_map.id] = item
        publish(initialized_item_event,
                params.merge(id: item_map.id, item_map: item_map))
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
      item_maps.each { |item_map| internal_new_item(item_map, {}) }
    end

    # TODO: Create an internal delete item method that 'delete item'
    # events are not missed if they happen between a select query and
    # an initialize_item event.

    #
    # Internal enumerators:
    #

    def internal_detect(params)
      if params.size == 1 && params.first.first == :id
        item = @items[params.first.last]
        item = nil if item && !match_item?(item, params)
        item
      else
        item = @items.detect { |id, item|
          match_item?(item, params)
        }
        item = item && item.last
      end
    end

    def internal_select(params)
      @items.values.select { |item| match_item?(item, params) }
    end

    #
    # Packet handling:
    #

    # TODO: Move to a module.

    def handle_dynamic_load(params)
      item_id = params[:id]

      debug log_format('handle dynamic load of item', "id: #{item_id}")

      return if !push_message(item_id, params[:message])

      item = item_by_params(id: item_id)
      return if item.nil?

      # Flush messages should be done after install. (Make sure
      # interfaces are loaded using sync.
      flush_messages(item.id,
                     item.public_method(:mac_address) && item.mac_address)
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

    def flush_messages(item_id, mac_address)
      return if item_id.nil? || item_id <= 0

      messages = @messages.delete(item_id)

      # The item must have a 'mac_address' attribute that will be used
      # as the eth_src address for sending packet out messages.
      if messages.nil? || mac_address.nil?
        debug log_format('flush messages failed', "id:#{item_id} mac_address:#{mac_address}")
        return
      end

      messages.each { |message|
        packet = message[:message]
        packet.match.in_port = OFPP_CONTROLLER
        packet.match.eth_src = mac_address

        @dp_info.send_packet_out(packet, OFPP_TABLE)
      }
    end

  end

end
