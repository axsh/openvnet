# -*- coding: utf-8 -*-

module Vnet::NodeApi

  class Base
    extend Vnet::Event::Dispatchable

    M = Vnet::Models

    def self.logger
      Celluloid.logger
    end

    class << self
      include Vnet::Event

      M = Vnet::Models

      def model_class
        @model_class ||= Vnet::Models.const_get(self.name.demodulize)
      end

      def execute(method_name, *args, &block)
        to_hash(self.__send__(method_name, *args, &block))
      end

      # TODO: Make 'execute_batch' only work for sequel model calls.
      def execute_batch(*args)
        methods = args.dup
        options = methods.last.is_a?(Hash) ? methods.pop : {}

        to_hash(methods.inject(self) do |klass, method|
            name, *args = method
            klass.__send__(name, *args)
          end, options)
      end

      # TODO: Look into why calling node_api methods like 'destroy'
      # goes through method_missing.
      def method_missing(method_name, *args, &block)
        if model_class.respond_to?(method_name)
          define_singleton_method(method_name) { |*args|
            model_class.__send__(method_name, *args, &block)
          }

          self.__send__(method_name, *args, &block)
        else
          super
        end
      end

      def transaction
        Sequel::DATABASES.first.transaction do
          yield
        end
      end

      def to_hash(data, options = {})
        case data
        when Array
          data.map { |d|
            to_hash(d, options)
          }
        when Hash
          data.each do |k, v|
            data[k] = to_hash(v, options)
          end
        when Vnet::Models::Base
          data.to_hash.tap do |h|
            options_for_recursive_call = options.dup
            fill = options_for_recursive_call.delete(:fill) || {}
            [fill].flatten.compact.each do |f|
              next if f.blank?
              if f.is_a?(Hash)
                key = f.keys.first
                value = f.values.first
                options_for_recursive_call.merge!(:fill => value)
              else
                key = f
              end
              h[key] = to_hash(data.__send__(key), options_for_recursive_call)
            end
          end
        else
          data
        end
      end

    end
  end

end
