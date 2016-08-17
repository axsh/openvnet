# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class InterfaceSegment < EventBase
    class << self

      def leased(interface_id, segment_id)
        # TODO: Add log_format-style logging to NodeApi's.
        logger.warn "XXXXXXXXXXXXXX leased interface_id:#{interface_id} segment_id:#{segment_id}"
        return if interface_id.nil? || segment_id.nil?

        # TODO: Add checks like with get_params and proper error reporting.
        filter = {
          interface_id: interface_id,
          segment_id: segment_id
        }

        transaction {
          return if M::InterfaceSegment[filter]
          create_with_transaction(filter)
        }.tap { |model|
          next if model.nil?
          dispatch_created_item_events(model)
        }
      end

      def released(interface_id, segment_id)
        logger.warn "XXXXXXXXXXXXXX released interface_id:#{interface_id} segment_id:#{segment_id}"
        return if interface_id.nil? || segment_id.nil?

        filter = {
          interface_id: interface_id,
          segment_id: segment_id
        }

        transaction {
          # If mac_lease does not exist, try to delete unless 'static==1'.
          model = M::InterfaceSegment[filter]

          if !model.static
            segments = M::MacLease.dataset.where(interface_id: interface_id).all.segments

            logger.warn "XXXXXXXXXXXXXX released segments:#{segments.inspect}"
          end
        }
      end

      #
      # Internal methods:
      #

      private

      def dispatch_created_item_events(model)
        logger.warn "XXXXXXXXXXXXXX dispatch_created_item_events model.inspect:#{model.inspect}"

        dispatch_event(INTERFACE_SEGMENT_CREATED_ITEM, model.to_hash)
      end

      def dispatch_deleted_item_events(model)
        logger.warn "XXXXXXXXXXXXXX dispatch_deleted_item_events model.inspect:#{model.inspect}"

        dispatch_event(INTERFACE_SEGMENT_DELETED_ITEM, id: model.id)
      end

    end
  end
end
