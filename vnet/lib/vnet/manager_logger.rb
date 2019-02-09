# -*- coding: utf-8 -*-

module Vnet
  class Manager
    module Logger
      def self.included(klass)
        klass.include(InstanceMethods)
      end

      module InstanceMethods
        private

        def log_format(message, values = nil)
          (@log_prefix || "") + message + (values ? " (#{values})" : '')
        end

        def log_format_h(message, values)
          values && values.map { |value|
            value.join(':')
          }.join(' ').tap { |str|
            return log_format(message, str)
          }
        end

        def log_format_a(message, values)
          values && values.join(', ').tap { |str|
            return log_format(message, str)
          }
        end

      end
    end
  end
end
