# -*- coding: utf-8 -*-

module Vnet::Openflow

  class Manager
    include Celluloid
    include Celluloid::Logger
    include FlowHelpers
    include Vnet::Event::Notifications

    def initialize(dp_info)
      @dp_info = dp_info

      @datapath_info = nil
      @items = {}
    end

    def item(params)
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
      @items.select { |id, item|
        match_item?(item, params)
      }.map { |id, item|
        item_to_hash(item)
      }
    end

    #
    # Other:
    #

    def packet_in(message)
      item = @items[message.cookie & COOKIE_ID_MASK]
      item.packet_in(message) if item
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

    #
    # Override these method to support additional parameters.
    #

    # Optimize this by returning a proc block.
    def match_item?(item, params)
      return false if params[:id] && params[:id] != item.id
      return false if params[:uuid] && params[:uuid] != item.uuid
      true
    end

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

      select_filter = select_filter_from_params(params)
      return nil if select_filter.nil?

      # After the db query, avoid yielding method calls until the item
      # is added to the items list and 'install' method is
      # called. Yielding method calls are any non-async actor method
      # calls or any other blocking methods.
      #
      # This is in particular important to avoid losing parameters
      # passed duing reinitialization of interfaces that e.g. pass
      # port number.
      #
      # Note that when adding events we need to ensure we subscribe to
      # db events for the item, if the events are for changes to data
      # we use from 'item_map'.
      #
      # We should try to use only static data from this query, and
      # rely on the 'install' method call as an event barrier for
      # dynamic data.

      item_map = select_item(select_filter)
      return nil if item_map.nil?

      if params[:reinitialize] == true
        @items.delete(item_map.id)
      else
        # Currently we're not keeping tabs on what interfaces are
        # being queried by interface manager, so check if it has been
        # created already.
        item = @items[item_map.id]
        return item if item
      end

      item_initialize(item_map).tap do |item|
        return unless item
        @items[item_map.id] = item
        publish(initialized_item_event, params.merge(id: item_map.id,
                                                     item_map: item_map))
      end
    end

    def item_initialize(item_map)
      # Must be implemented by subclass
      raise NotImplementedError
    end

    def initialized_item_event
      # Must be implemented by subclass
      raise NotImplementedError
    end

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

    def log_format(message, values = nil)
      "#{@dp_info.try(:dpid_s)} #{self.class.name.to_s.demodulize.underscore}: #{message}" + (values ? " (#{values})" : '')
    end
  end
end
