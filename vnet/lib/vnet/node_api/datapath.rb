# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class Datapath < Base
    class << self
      def create(options)
        super.tap do |datapath|
          dispatch_event(DATAPATH_CREATED_ITEM, id: datapath.id, dpid: datapath.dpid)
        end
      end

      def destroy(uuid)
        super.tap do |datapath|
          dispatch_event(DATAPATH_DELETED_ITEM, id: datapath.id)
        end
      end
    end
  end
end
