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
      # Override find method to only use the unique identifiers to find an existing tunnel
      #
      def find(options)
        tunnel = super({
          :src_datapath_id => options[:src_datapath_id],
          :dst_datapath_id => options[:dst_datapath_id],
          :src_interface_id => options[:src_interface_id],
          :dst_interface_id => options[:dst_interface_id]
        })
      end

      def create_or_find(options)
        # Only create a tunnel if it doesn't exist yet
        tunnel = find(options)
        if !tunnel
          tunnel = create(options)
        end
        tunnel
      end

      #
      # Internal methods:
      #

      private

      def dispatch_created_item_events(model)
         dispatch_event(ADDED_TUNNEL, model.to_hash)
      end

      def dispatch_deleted_item_events(model)
         dispatch_event(REMOVED_TUNNEL, id: model.id)

        # no dependencies
      end

    end
  end
end

