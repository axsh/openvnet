# -*- coding: utf-8 -*-

module Vnet::NodeApi

  class AssocBase < EventBase
    class << self

      # Send events to load all item assocs for a parent item.
      def dispatch_added_assocs_for_parent_id(parent_id)
        transaction {
          assoc_class.dataset.where(parent_id_type => parent_id).all { |assoc_model|
            dispatch_created_item_events(assoc_model)
          }
        }
      end

      private

      def parent_class
        raise NotImplementedError
      end

      def parent_id_type
        raise NotImplementedError
      end

      def assoc_class
        raise NotImplementedError
      end

      def assoc_id_type
        raise NotImplementedError
      end

      def event_created_name
        raise NotImplementedError
      end

      def event_deleted_name
        raise NotImplementedError
      end

      # TODO: Add helper methods to remove timestamps and such.
      #
      # TODO: This needs to use a param pair as this now collides with
      # id keys.
      def event_created_hash(map)
        map.to_hash.tap { |params|
          params[:id] = params.delete(parent_id_type)

          params.delete(:created_at)
          params.delete(:updated_at)
          params.delete(:deleted_at)
          params.delete(:is_deleted)
        }
      end

      def event_deleted_hash(map)
        { :id => map[parent_id_type],
          assoc_id_type => map[assoc_id_type]
        }
      end

      def dispatch_created_item_events(model)
        dispatch_event(event_created_name, event_created_hash(model))
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(event_deleted_name, event_deleted_hash(model))
      end

    end
  end

end
