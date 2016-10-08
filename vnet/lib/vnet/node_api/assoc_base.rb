# -*- coding: utf-8 -*-

module Vnet::NodeApi

  class AssocBase < EventBase
    class << self

      # Send events to load all item assocs for a parent item.
      def dispatch_added_assocs_for_parent_id(parent_id)
        transaction {
          assoc_class.dataset.where(parent_id_type => parent_id).all { |assoc_model|
            Celluloid::Logger.warn "XXXXXXXXXXX #{assoc_model.inspect}"

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
      def event_created_hash(model_map)
        (model_map.is_a?(Hash) ? model_map.dup : model_map.to_hash).tap { |event_hash|
          event_hash[:id] = event_hash.delete(parent_id_type)
        }
      end

      def event_deleted_hash(model_map)
        { :id => model_map[parent_id_type],
          assoc_id_type => model_map[assoc_id_type]
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
