# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class Segment < EventBase
    valid_update_fields []

    class << self
      private

      def create_with_transaction(options)
        options = options.dup

        topology_id = options.delete(:topology_id)

        transaction {
          handle_new_uuid(options)

          internal_create(options).tap { |model|
            next if model.nil?

            M::TopologySegment.create(segment_id: model.id, topology_id: topology_id) if topology_id
          }
        }
      end

      def dispatch_created_item_events(model)
        filter = { segment_id: model.id }

        # 0009_topology
        TopologySegment.dispatch_created_where(filter, model.created_at)
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(SEGMENT_DELETED_ITEM, id: model.id)

        filter = { segment_id: model.id }

        # 0009_topology
        TopologySegment.dispatch_deleted_where(filter, model.deleted_at)
        # 0010_segment
        MacLease.dispatch_deleted_for_segment(model.id, model.deleted_at)
        # 0011_assoc_interface
        InterfaceSegment.dispatch_deleted_where(filter, model.deleted_at)
      end

    end
  end
end
