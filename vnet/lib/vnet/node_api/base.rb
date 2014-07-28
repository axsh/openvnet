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
          next if model.nil?
          transaction { model.destroy }
        end
      end

      def model_class(name = nil)
        Vnet::Models.const_get(name ? name.to_s.camelize : self.name.demodulize)
      end

      def execute(method_name, *args, &block)
        to_hash(self.__send__(method_name, *args, &block))
      end

      def execute_batch(*args)
        methods = args.dup
        options = methods.last.is_a?(Hash) ? methods.pop : {}
        transaction do
          to_hash(methods.inject(self) do |klass, method|
            name, *args = method
            klass.__send__(name, *args)
          end, options)
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

      #
      # Internal methods:
      #

      private

      # Make sure events are dispatched for entries deleted by
      # sequel's association_dependencies plugin. We send events for
      # all entries with 'deleted_at' within the last 3 seconds in
      # order to account for the possibility that the two timestamps
      # are mismatched.
      #
      # Note: Investigate if parent's deleted_at always gets written
      # last, if so remote the 3 second grace time.

      def dispatch_deleted_events(model_sym, id_sym, item, event)
        filter_id = { id_sym => item.id }
        filter_date = ['deleted_at >= ? || deleted_at = NULL', item.deleted_at - 3]

        model_class(model_sym).with_deleted.where(filter_id).filter(*filter_date).each { |model|
          dispatch_event(event, model.to_hash)
        }
      end

    end
  end
end
