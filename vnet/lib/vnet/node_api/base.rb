# -*- coding: utf-8 -*-
module Vnet::NodeApi
  class Base
    extend Vnet::Event::Dispatchable

    def self.logger
      Vnet.logger
    end

    class << self
      include Vnet::Event

      def create(options)
        model = nil
        transaction do
          model = model_class.create(options)
        end
        model
      end

      def update(uuid, options)
        model_class[uuid].tap do |model|
          transaction { model.update(options) }
        end
      end

      def destroy(uuid)
        model_class[uuid].tap do |model|
          transaction { model.destroy }
        end
      end

      # Events added during the transaction are guaranteed to not be dispatched until the transaction has finished.
      def execute(method_name, *args, &block)
        result = event_transaction do
          self.__send__(method_name, *args, &block)
        end
        to_hash(result)
      end

      # Events added during the transaction are guaranteed to not be dispatched until the transaction has finished.
      def execute_batch(*args)
        methods = args.dup
        options = methods.last.is_a?(Hash) ? methods.pop : {}
        result = nil
        event_transaction do
          result = methods.inject(self) do |klass, method|
            name, *args = method
            klass.__send__(name, *args)
          end
        end
        to_hash(result, options)
      end

      alias_method :dispatch_event_without_transaction, :dispatch_event
      def dispatch_event(event, options = {})
        if Thread.current[:event_transaction]
          Thread.current[:event_queue] << { event: event, options: options }
        else
          dispatch_event_without_transaction(event, options)
        end
      end

      protected

      def model_class(name = nil)
        Vnet::Models.const_get(name ? name.to_s.camelize : self.name.demodulize)
      end

      def event_transaction(&block)
        if Thread.current[:event_transaction]
          yield
        else
          Thread.current[:event_transaction] = true
          Thread.current[:event_queue] ||= []
          begin
            yield.tap do
              Thread.current[:event_queue].each do |event|
                dispatch_event_without_transaction(event[:event], event[:options])
              end
            end
          ensure
            Thread.current[:event_transaction] = false
            Thread.current[:event_queue] = []
          end
        end
      end

      def method_missing(method_name, *args, &block)
        if model_class.respond_to?(method_name)
          define_singleton_method(method_name) do |*args|
            transaction do
              model_class.__send__(method_name, *args, &block)
            end
          end
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
