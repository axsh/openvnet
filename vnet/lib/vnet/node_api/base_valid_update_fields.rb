# -*- coding: utf-8 -*-

module Vnet::NodeApi
  module BaseValidateUpdateFields

    module InstanceMethods
    end

    module ClassMethods
      def has_valid_update_fields?
        @valid_update_fields
      end

      def set_valid_update_fields(fields)
        @valid_update_fields = fields
      end

      def validate_update_fields(options)
        options.each { |key, value|
          if !@valid_update_fields.include?(key)
            raise ArgumentError, "Unsupported update key: #{key}"
          end
        }
      end

    end

  end
end
