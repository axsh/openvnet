# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class Tunnel < EventBase
    class << self

      def update_mode(id, mode)
        transaction do
          model_class[id].tap do |obj|
            return unless obj
            obj.mode = mode
            obj.save_changes
          end
        end
      end

      #
      # Internal methods:
      #

      private

      def dispatch_created_item_events(model)
        # dispatch_event(ADDED_TUNNEL, model.to_hash)
      end

      def dispatch_deleted_item_events(model)
        # dispatch_event(REMOVED_TUNNEL, id: model.id)
      end

    end
  end
end
