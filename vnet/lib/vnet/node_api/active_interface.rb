# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class ActiveInterface < Base
    class << self

      # Currently only supports very simple handling of race
      # conditions, etc.

      def create(options)
        options = options.dup

        interface_id = options[:interface_id]

        transaction {
          # Assuming label == nil for now:

          active_models = model_class.where(interface_id: interface_id).all

          Celluloid::Logger.debug "active interfaces pre-prune: #{active_models.inspect}"

          prune_old(active_models)

          Celluloid::Logger.debug "active interfaces post-prune: #{active_models.inspect}"

          model = super(options)

          Celluloid::Logger.debug "created active interface: #{model.inspect}"

          model

        }.tap { |model|
          dispatch_event(ACTIVE_INTERFACE_CREATED_ITEM, model.to_hash)
        }
      end

      def destroy(id)
        super.tap do |model|
          next unless model
          dispatch_event(ACTIVE_INTERFACE_DELETED_ITEM, model.to_hash)
        end
      end

      #
      # Internal methods:
      #

      private

      def prune_old(active_models)
        active_models.delete_if { |active_model|
          # TODO: Catch exceptions.

          # Currently default to destroying all:

          active_model.destroy
        }
      end

    end
  end
end
