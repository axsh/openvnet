# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class Network < EventBase
    class << self
      private

      def dispatch_created_item_events(model)
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(NETWORK_DELETED_ITEM, id: model.id)

        filter = { network_id: model.id }

        # 0001_origin
        ActiveNetwork.dispatch_deleted_where(filter, model.deleted_at)
        # IpAddresses.dispatch_deleted_where(filter, model.deleted_at) # Needed? We're deleting the network.
        DatapathNetwork.dispatch_deleted_where(filter, model.deleted_at)
        Route.dispatch_deleted_where(filter, model.deleted_at)
        # VlanTranslation.dispatch_deleted_where(filter, model.deleted_at)

        # 0002_services
        # LeasePolicyBaseNetwork.dispatch_deleted_where(filter, model.deleted_at)
      end

    end
  end
end
