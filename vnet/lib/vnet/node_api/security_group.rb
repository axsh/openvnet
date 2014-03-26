# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class SecurityGroup < Base
    class << self
      def update(uuid, options)
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
        group = super(id)

        dispatch_event(REMOVED_SECURITY_GROUP, id: group.id)

        nil
      end
    end
  end
end
