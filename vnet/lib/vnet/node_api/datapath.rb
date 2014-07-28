# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class Datapath < Base
    class << self
      def create(options)
        super.tap do |datapath|
          dispatch_event(DATAPATH_CREATED_ITEM, datapath.to_hash)
        end
      end

      def destroy(uuid)
        super.tap do |datapath|
          dispatch_event(DATAPATH_DELETED_ITEM, datapath.to_hash)
        end
      end
    end
  end
end
