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
          @valid_update_fields.detect { |valid_key|
            key == valid_key || key == valid_key.to_s
          }.tap { |result|
            raise ArgumentError, "Unsupported update key: #{key}" if result.nil?
          }
        }
      end

    end

  end
end
