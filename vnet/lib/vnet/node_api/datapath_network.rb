# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class DatapathNetwork < Base
    class << self
      def create(options)
        super.tap do |datapath_network|
          dispatch_event(ADDED_DATAPATH_NETWORK, datapath_network_id: datapath_network.id)
        end
      end

      def destroy(uuid)
        super.tap do |datapath_network|
          dispatch_event(REMOVED_DATAPATH_NETWORK, datapath_network_id: datapath_network.id)
        end
      end
    end
  end
end
