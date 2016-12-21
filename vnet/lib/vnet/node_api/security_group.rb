# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class SecurityGroup < EventBase
    valid_update_fields [:display_name, :description, :rules]

    class << self
      def update_uuid(uuid, options)
        rules = options[:rules]

        secg = transaction do
          model_class[uuid].tap do |model|
            model.set(options)
            model.save_changes
            model
          end
        end

        if rules
          dispatch_event(UPDATED_SG_RULES,
            id: secg.id,
            rules: rules
          )
        end

        secg
      end

      def destroy(id)
        group = super(id, {})

        dispatch_event(REMOVED_SECURITY_GROUP, id: group.id)

        nil
      end

      private

      def dispatch_created_item_events(model)
      end

      def dispatch_deleted_item_events(model)
      end

    end
  end
end
