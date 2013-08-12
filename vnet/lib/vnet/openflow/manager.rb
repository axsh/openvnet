# -*- coding: utf-8 -*-

module Vnet::Openflow

  class Manager
    include Celluloid
    include Celluloid::Logger
    include FlowHelpers

    def initialize(dp)
      @datapath = dp
      @items = {}

      @dpid = @datapath.dpid
      @dpid_s = "0x%016x" % @datapath.dpid
    end

    def item(params)
      item_to_hash(item_by_params(params))
    end

    def packet_in(message)
      item = @items[message.cookie & COOKIE_ID_MASK]
      item.packet_in(message) if item
      nil
    end

    #
    # Internal methods:
    #

    private

    def item_to_hash(item)
      item && item.to_hash
    end

    def item_by_params(params)
      item = item_by_params_direct(params)

      if (item && params[:reinitialize] == false) || params[:dynamic_load] == false
        return item
      end

      select = case
               when params[:id]   then {:id => params[:id]}
               when params[:uuid] then params[:uuid]
               else
                 raise("Missing item id/uuid parameter.")
               end

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
        item = @items.detect { |id, item| item.uuid == params[:uuid] }
        return item && item[1]
      else
        raise("Missing item id/uuid parameter.")
      end
    end

  end

end
