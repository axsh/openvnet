# -*- coding: utf-8 -*-

module Vnet::NodeApi

  class AssocBase < EventBase
    class << self
      private

      def parent_id_type
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

      def event_created_hash(model_map)
        (model_map.is_a?(Hash) ? model_map.dup : model_map.to_hash).tap { |event_hash|
          event_hash[:id] = event_hash.delete(parent_id_type)
        }
      end

      def event_deleted_hash(model_map)
        { :id => model_map[:interface_id],
          assoc_id_type => model_map[:id]
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
