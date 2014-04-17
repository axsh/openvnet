# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class NetworkService < Base
    class << self
      def create(options)
        super.tap do |network_service|
          dispatch_event(SERVICE_CREATED_ITEM, network_service)
        end
      end

      def destroy(uuid)
        super.tap do |network_service|
          dispatch_event(SERVICE_DELETED_ITEM, network_service)
        end
      end
    end
  end
end
