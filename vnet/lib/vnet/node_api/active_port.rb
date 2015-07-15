# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class ActivePort < EventBase
    class << self
      private

      # Currently only supports very simple handling of race
      # conditions, etc.
      def create_with_transaction(options)
        options = options.dup

        port_id = options[:port_id]
        datapath_id = options[:datapath_id]
        label = options[:label]
        singular = options[:singular]

        transaction {
          active_models = model_class.where(port_id: port_id).all

          old_model = prune_old(active_models, datapath_id)
          old_model = prune_for_singular(active_models, datapath_id) if singular

          old_model.destroy if old_model

          internal_create(options)
        }
      end

      def dispatch_created_item_events(model)
        dispatch_event(ACTIVE_PORT_CREATED_ITEM, model.to_hash)
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(ACTIVE_PORT_DELETED_ITEM, id: model.id)
      end

      def prune_old(active_models, ignore_datapath_id)
        old_model = nil

        active_models.delete_if { |active_model|
          if active_model.datapath_id == ignore_datapath_id
            old_model = active_model
            next
          end

          # TODO: Catch exceptions.
          # Only destroy active entries that are old.
          # Currently default to destroying all:
          # next unless active_model.updated_at + timeout < current_time
          # active_model.destroy
        }

        old_model
      end

      def prune_for_singular(active_models, ignore_datapath_id)
        old_model = nil

        active_models.delete_if { |active_model|
          if active_model.datapath_id == ignore_datapath_id
            old_model = active_model
            next
          end

          # Currently we destroy everything.
          active_model.destroy
        }

        old_model
      end

    end
  end
end
