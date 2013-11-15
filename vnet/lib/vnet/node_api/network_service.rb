# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class NetworkService < Base
    class << self
      def create(options)
        super.tap do |network_service|
          dispatch_event(ADDED_SERVICE, :id => network_service.id)
        end
      end

      def destroy(uuid)
        super.tap do |network_service|
          dispatch_event(REMOVED_SERVICE, :id => network_service.id)
        end
      end
    end
  end
end
