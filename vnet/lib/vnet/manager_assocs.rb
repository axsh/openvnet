# -*- coding: utf-8 -*-

module Vnet
  module ManagerAssocs

    def self.included(klass)
      klass.extend(ClassMethods)
    end

    module ClassMethods
      def subscribe_assoc_events(self_name, other_name)
        subscribe_event "#{self_name}_added_#{other_name}", "added_#{other_name}"
        subscribe_event "#{self_name}_removed_#{other_name}", "removed_#{other_name}"

        define_method "added_#{other_name}".to_sym do |params|
          (internal_detect_by_id_with_error(params) || return).tap { |item|
            item.added_assoc(other_name, params)
          }
        end

        define_method "removed_#{other_name}".to_sym do |params|
          (internal_detect_by_id_with_error(params) || return).tap { |item|
            item.removed_assoc(other_name, params)
          }
        end
      end
    end

  end
end
