# -*- coding: utf-8 -*-

# Set is_deleted column to id on deletion to allow for unique
# constraints.

module Sequel
  module Plugins
    module ParanoiaIsDeleted

      def self.apply(model, opts = OPTS)
        model.plugin :paranoia
      end

      module InstanceMethods
        def before_destroy
          self.is_deleted = self.id
          super
        end
      end

    end
  end
end
