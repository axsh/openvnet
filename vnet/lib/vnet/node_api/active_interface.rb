# -*- coding: utf-8 -*-

module Vnet::NodeApi

  class ActiveInterface < EventBase
    class << self

      #
      # Internal methods:
      #

      private

      # Currently only supports very simple handling of race
      # conditions, etc.
      def create_with_transaction(options)
        options = options.dup

        interface_id = options[:interface_id]
        datapath_id = options[:datapath_id]
        label = options[:label]
        singular = options[:singular]

        transaction {
          active_models = model_class.where(interface_id: interface_id).all
          old_model = prune_old(active_models, datapath_id)
          old_model = prune_for_singular(active_models, datapath_id) if singular

          # TODO: Delete, don't update.
          if old_model
            model = old_model
            model.set(port_name: options[:port_name],
                      label: label,
                      singular: singular,
                      enable_routing: options[:enable_routing])
            model.save_changes
            
            Celluloid::Logger.debug "updated active interface: #{model.inspect}"

          else
            model = super(options)
            Celluloid::Logger.debug "created active interface: #{model.inspect}"
          end

          model
        }
      end

      def dispatch_created_item_events(model)
        dispatch_event(ACTIVE_INTERFACE_CREATED_ITEM, model.to_hash)
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(ACTIVE_INTERFACE_DELETED_ITEM, id: model.id)
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
