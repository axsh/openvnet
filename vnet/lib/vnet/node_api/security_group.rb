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
          dispatch_event(UPDATED_FILTER,
            event: :update_rules,
            id: secg.id,
            rules: rules
          )
          #TODO: Update reference as well
        end

        secg
      end
    end
  end
end
