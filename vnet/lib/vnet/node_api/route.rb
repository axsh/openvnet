# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class Route < Base
    class << self

      # Currently only supports very simple handling of race
      # conditions, etc.

      def create(options)
        super.tap { |model|
          next if model.nil?
          dispatch_event(ROUTE_CREATED_ITEM, model.to_hash)
        }
      end

      def destroy(id)
        super.tap { |model|
          next if model.nil?
          dispatch_event(ROUTE_DELETED_ITEM, model.to_hash)
        }
      end

    end
  end
end
