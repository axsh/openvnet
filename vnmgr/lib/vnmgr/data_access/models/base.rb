# -*- coding: utf-8 -*-
module Vnmgr::DataAccess::Models
  class Base
    attr_accessor :model_class
    def initialize
      @model_class = Vnmgr::Models.const_get(self.class.name.demodulize)
    end

    def execute_batch(*args)
      methods = args.dup
      options = methods.last.is_a?(Hash) ? methods.pop : {}
      Sequel::DATABASES.first.transaction do
        to_hash(methods.inject(model_class) do |klass, method|
          name, *args = method
          klass.__send__(name, *args)
        end, options)
      end
    end

    def method_missing(method_name, *args, &block)
      if model_class.respond_to?(method_name)
        define_singleton_method(method_name) do |*args|
          # TODO db transaction
          Sequel::DATABASES.first.transaction do
            to_hash(model_class.__send__(method_name, *args, &block))
          end
        end
        self.__send__(method_name, *args, &block)
      else
        super
      end
    end

    def to_hash(data, options = {})
      case data
      when Array
        data.map { |d|
          to_hash(d, options)
        }
      when Vnmgr::Models::Base
        data.to_hash.tap do |h|
          options_for_recursive_call = options.dup
          fill = options_for_recursive_call.delete(:fill)
          [fill].flatten.compact.each do |f|
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
