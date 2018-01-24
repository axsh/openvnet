# -*- coding: utf-8 -*-

module Vnet::NodeApi

  class Topology < EventBase
    valid_update_fields []

    class << self
      private

      def dispatch_created_item_events(model)
        dispatch_event(TOPOLOGY_CREATED_ITEM, event_hash_prepare(model))
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(TOPOLOGY_DELETED_ITEM, id: model.id)

        filter = { topology_id: model.id }

        # 0018_topology_lease
        DatapathNetwork.dispatch_deleted_where(filter, model.deleted_at)
        DatapathSegment.dispatch_deleted_where(filter, model.deleted_at)
        DatapathRouteLink.dispatch_deleted_where(filter, model.deleted_at)
      end

    end
  end

  class TopologyLayer < EventBase
    valid_update_fields []

    class << self
      private

      def dispatch_created_item_events(model)
        dispatch_event(TOPOLOGY_ADDED_LAYER, event_hash_prepare(model, :layer))
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(TOPOLOGY_REMOVED_LAYER, event_hash_prepare(model, :layer))
      end

    end
  end

  class TopologyAssocBase < AssocBase
    class << self
      private

      def parent_class
        Topology
      end

      def parent_id_type
        :topology_id
      end

    end
  end

  class TopologyDatapath < TopologyAssocBase
    valid_update_fields []

    class << self
      private

      def create_with_transaction(options)
        options = options.dup

        transaction {
          options[:ip_lease_id] = detect_ip_lease(options) if options[:ip_lease_id].nil?

          # TODO: Verify ip_lease_id's interface_id is valid.
          # TODO: Verify interface is host mode.
          # TODO: Verify interface and datapath matches.

          internal_create(options)
        }
      end

      def assoc_class
        TopologyDatapath
      end

      def assoc_id_type
        :datapath_id
      end

      def event_created_name
        TOPOLOGY_ADDED_DATAPATH
      end

      def event_deleted_name
        TOPOLOGY_REMOVED_DATAPATH
      end

      def detect_ip_lease(params)
        interface_id = params[:interface_id] || return
        datapath_id = params[:datapath_id] || return

        ds = M::IpLease.dataset
        ds = ds.where(ip_leases__interface_id: interface_id)
        ds = ds.where_datapath_id_and_interface_mode(datapath_id, Vnet::Constants::Interface::MODE_HOST)
        lease = ds.select_all(:ip_leases).first

        lease && lease.id
      end

    end
  end

  class TopologyNetwork < TopologyAssocBase
    valid_update_fields []

    class << self
      private

      def assoc_class
        TopologyNetwork
      end

      def parent_id_type
        :topology_id
      end

      def assoc_id_type
        :network_id
      end

      def event_created_name
        TOPOLOGY_ADDED_NETWORK
      end

      def event_deleted_name
        TOPOLOGY_REMOVED_NETWORK
      end

    end
  end

  class TopologySegment < TopologyAssocBase
    valid_update_fields []

    class << self
      private

      def assoc_class
        TopologySegment
      end

      def assoc_id_type
        :segment_id
      end

      def event_created_name
        TOPOLOGY_ADDED_SEGMENT
      end

      def event_deleted_name
        TOPOLOGY_REMOVED_SEGMENT
      end

    end
  end

  class TopologyRouteLink < TopologyAssocBase
    valid_update_fields []

    class << self
      private

      def assoc_class
        TopologyRouteLink
      end

      def assoc_id_type
        :route_link_id
      end

      def event_created_name
        TOPOLOGY_ADDED_ROUTE_LINK
      end

      def event_deleted_name
        TOPOLOGY_REMOVED_ROUTE_LINK
      end

    end
  end

end
