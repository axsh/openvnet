# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class EventBase < Base
    class << self

      def create(options)
        create_with_transaction(options).tap { |model|
          next if model.nil?
          dispatch_created_item_events(model)
        }
      end

      def destroy(filter)
        destroy_with_transaction(filter).tap { |model|
          next if model.nil?
          dispatch_deleted_item_events(model)
        }
      end

      # Make sure events are dispatched for entries deleted by
      # sequel's association_dependencies plugin. We send events for
      # all entries with 'deleted_at' within the last 3 seconds in
      # order to account for the possibility that the two timestamps
      # are mismatched.
      #
      # Note: Investigate if parent's deleted_at always gets written
      # last, if so remove the 3 second grace time.

      def dispatch_deleted_where(filter, deleted_at)
        filter_date = ['deleted_at >= ? || deleted_at = NULL', deleted_at - 3]

        model_class.with_deleted.where(filter).filter(*filter_date).each { |model|
          dispatch_deleted_item_events(model)
        }
      end

      #
      # Internal methods:
      #

      private

      def internal_create(options)
        model_class.create(options)
      end

      def internal_destroy(model)
        model.destroy
      end

      #
      # Customizable methods:
      #

      # Allows the model to be created/deleted within a
      # transaction. The overloading method needs to add the
      # transaction block and call internal_create/delete.

      def create_with_transaction(options)
        model_class.create(options)
      end

      def destroy_with_transaction(filter)
        model_class[filter].destroy
      end

      def dispatch_created_item_events(model)
        raise NotImplementedError
      end

      def dispatch_deleted_item_events(model)
        raise NotImplementedError
      end

    end
  end
end
