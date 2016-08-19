# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class InterfaceSegment < EventBase
    class << self

      def leased(interface_id, segment_id)
        # TODO: Add log_format-style logging to NodeApi's.
        logger.warn "XXXXXXXXXXXXXX leased interface_id:#{interface_id} segment_id:#{segment_id}"
        # TODO: Do proper param checks.
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

          if model && !model.static
            should_destroy = M::MacLease.dataset.where(interface_id: interface_id).segments.where(segment_id: segment_id).empty?

            logger.warn "XXXXXXXXXXXXXX released should_destroy:#{should_destroy}"
            model.destroy if should_destroy
          end

          model
        }
      end

      def set_static(interface_id, segment_id)
        logger.warn "XXXXXXXXXXXXXX set_static interface_id:#{interface_id} segment_id:#{segment_id}"
        return if interface_id.nil? || segment_id.nil?

        filter = {
          interface_id: interface_id,
          segment_id: segment_id
        }

        transaction {
          model = M::InterfaceSegment[filter]

          if model
            # Do not dispatch any events if already set.
            return model if model.static

            model.static = true

            # TODO: Make a helper method that saves changes and
            # dispatches events / adds events to be dispatched to an
            # array.
            #
            # add_event_to_queue(Foo, event, model, changed_columns)

            if model.save
              # TODO: Do proper dispatch_event things here. (should be outside transaction)
              logger.warn "XXXXXXXXXXXX set_static 'dispatch_updated_item_events' model:#{model.inspect}"
              # HACK: dispatch_updated_item_events(model, changed_columns)
            end

            return
          end

          create_with_transaction(filter.merge!(static: true))

        }.tap { |model|
          next if model.nil?

          logger.warn "XXXXXXXXXXXX set_static 'dispatch_created_item_events' model:#{model.inspect}"
          dispatch_created_item_events(model)
        }
      end

      def clear_static(interface_id, segment_id)
        logger.warn "XXXXXXXXXXXXXX clear_static interface_id:#{interface_id} segment_id:#{segment_id}"
        return if interface_id.nil? || segment_id.nil?
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
