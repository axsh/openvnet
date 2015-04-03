# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class SecurityGroupInterface < EventBase
    class << self
      include Vnet::Helpers::Event

      def destroy_where(filter)
        count = 0

        model_class.dataset.where(filter).all.each { |model|
          next if model.destroy.nil?
          count += 1
          dispatch_deleted_item_events(model)
        }

        count
      end

      #
      # Internal methods:
      #

      private

      def dispatch_created_item_events(model)
        group = model.security_group

        dispatch_event(ADDED_INTERFACE_TO_SG,
                       id: group.id,
                       interface_id: model.interface_id,
                       interface_cookie_id: group.interface_cookie_id(model.interface_id))

        dispatch_update_sg_ip_addresses(group)
      end

      def dispatch_deleted_item_events(model)
        group = model.security_group

        dispatch_event(REMOVED_INTERFACE_FROM_SG,
                       id: group.id,
                       interface_id: model.interface_id)

        dispatch_update_sg_ip_addresses(group)

        # no dependencies
      end

    end
  end
end
