# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class DatapathNetwork < Base
    class << self
      def create(options)
        super.tap do |dpn|
          dpn && dispatch_event(ADDED_DATAPATH_NETWORK,
                                id: dpn.datapath_id,
                                network_id: dpn.network_id,
                                dpn_id: dpn.id)
        end
      end

      def destroy(datapath_id: datapath_id, network_id: network_id)
        transaction {
          model_class.find(datapath_id: datapath_id, network_id: network_id).tap(&:destroy)
        }.tap do |dpn|
          dpn && dispatch_event(REMOVED_DATAPATH_NETWORK,
                                id: dpn.datapath_id,
                                network_id: dpn.network_id,
                                dpn_id: dpn.id)
        end
      end
    end
  end
end
