# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class ActiveInterface < Base
    class << self

      # Currently only supports very simple handling of race
      # conditions, etc.

      def create(options)
        options = options.dup

        interface_id = options[:interface_id]
        datapath_id = options[:datapath_id]
        label = options[:label]
        singular = options[:singular]

        transaction {

          active_models = model_class.where(interface_id: interface_id).all
          Celluloid::Logger.debug "active interfaces pre-prune: #{active_models.inspect}"

          old_model = prune_old(active_models, datapath_id)
          Celluloid::Logger.debug "active interfaces post-prune_old: #{active_models.inspect}"

          old_model = prune_for_singular(active_models, datapath_id) if singular
          Celluloid::Logger.debug "active interfaces post-prune_for_singular: #{active_models.inspect}"

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

        }.tap { |model|
          case
          when model.nil?
            next
          when model.new?
            dispatch_event(ACTIVE_INTERFACE_CREATED_ITEM, model.to_hash)
          else
            dispatch_event(ACTIVE_INTERFACE_UPDATED, model.to_hash)
          end
        }
      end

      def destroy(id)
        super.tap do |model|
          next if model.nil?
          dispatch_event(ACTIVE_INTERFACE_DELETED_ITEM, model.to_hash)
        end
      end

      #
      # Internal methods:
      #

      private

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
