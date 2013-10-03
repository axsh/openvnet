# -*- coding: utf-8 -*-

module Vnet::Openflow

  class Manager
    include Celluloid
    include Celluloid::Notifications
    include Celluloid::Logger
    include FlowHelpers
    include Vnet::Event

    class << self
      def events
        @events ||= {}
      end

      def subscribe_event(event, method = nil, &bloc)
        self.events[event] = method
      end
    end

    def initialize(dp)
      @datapath = dp
      @datapath_id = nil
      @items = {}

      @dpid = @datapath.dpid
      @dpid_s = "0x%016x" % @datapath.dpid
      subscribe_events
    end

    def item(params)
      item_to_hash(item_by_params(params))
    end

    def unload(params)
      item = item_by_params_direct(params)
      return nil if item.nil?

      item_hash = item_to_hash(item)
      delete_item(item)
      item_hash
    end

    def packet_in(message)
      item = @items[message.cookie & COOKIE_ID_MASK]
      item.packet_in(message) if item
      nil
    end

    def set_datapath_id(datapath_id)
      if @datapath_id
        raise("Manager.set_datapath_id called twice.")
      end

      @datapath_id = datapath_id
      
      # We need to update remote interfaces in case they are now in
      # our datapath.
    end

    def handle_event(event, params)
      debug log_format("handle event #{event}", "#{params.inspect}")

      item = @items[params[:target_id]]
      if handler = self.class.events[event]
        __send__(handler, item, params)
      end

      return nil
    end
    #
    # Internal methods:
    #

    private

    def item_to_hash(item)
      item && item.to_hash
    end

    def item_by_params(params)
      if params[:reinitialize] != true
        item = item_by_params_direct(params)

        if item || params[:dynamic_load] == false
          return item
        end
      end

      select = select_filter_from_params(params)
      return nil if select.nil?

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

      item_map = select_item(select)
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

      create_item(item_map, params)
    end

    def item_by_params_direct(params)
      case
      when params[:id] then return @items[params[:id]]
      when params[:uuid]
        uuid = params[:uuid]
        item = @items.detect { |id, item| item.uuid == uuid }
        return item && item[1]
      else
        raise("Missing item id/uuid parameter.")
      end
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

    def subscribe_events
      self.class.events.each do |event, method|
        # FIXME
        # We should raise error if Celluloid::Notifications is not working.
        # If you know how to start notifier actor correctly in rspec, remove 'begin ~ rescue' clouse.
        begin
          subscribe(event, :handle_event)
        rescue Celluloid::DeadActorError => e
          error e.message
          error e.backtrace
        end
      end
    end
  end

end
