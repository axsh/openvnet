# TODO: Remove this.

module Sequel
  module Plugins
    module ParanoiaWithUniqueConstraint
      def self.apply(model, opts=OPTS)
        model.plugin :paranoia
      end

      module InstanceMethods
        def before_destroy
          self.deleted = id
        end
      end
    end
  end
end
