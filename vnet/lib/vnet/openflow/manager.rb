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

    #
    # Internal methods:
    #

    private

    def item_to_hash(item)
      item && item.to_hash
    end

    def item_by_params(params)
      item = item_by_params_direct(params)

      if item || params[:dynamic_load] == false
        return item
      end

      select = case
               when params[:id]   then {:id => params[:id]}
               when params[:uuid] then params[:uuid]
               else
                 raise("Missing item id/uuid parameter.")
               end

      create_item(select_item(select))
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
