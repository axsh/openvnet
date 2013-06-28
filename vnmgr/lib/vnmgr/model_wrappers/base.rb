# -*- coding: utf-8 -*-
require 'ostruct'

module Vnmgr::ModelWrappers
  class Batch
    def initialize(model)
      @model = model
      @methods = []
    end

    def method_missing(method_name, *args)
      @methods << [method_name, *args]
      self
    end

    def commit(options = {})
      @model._execute_batch(@methods, options)
    end
  end

  class Base < OpenStruct
    class << self
      def set_proxy(conf)
        @@proxy = Vnmgr::DataAccess.get_proxy(conf)
      end

      def _proxy
        @@proxy
      end

      def batch(&block)
        if block_given?
          yield(Batch.new(self)).commit
        else
          Batch.new(self)
        end
      end

      def method_missing(method_name, *args, &block)
        wrap(_call_proxy_method(method_name, *args, &block))
      end

      def _execute_batch(methods, options = {})
        methods = methods.dup
        methods << options
        wrap(_call_proxy_method(:execute_batch, *methods), options)
      end

      def _call_proxy_method(method_name, *args, &block)
        klass = _proxy.send(self.name.demodulize.underscore.to_sym)
        klass.send(method_name, *args, &block)
      end

      protected
      def wrap(data, options = {})
        case data
        when Array
          data.map{|d| wrap(d, options) }
        when Hash
          ::Vnmgr::ModelWrappers.const_get(data.delete(:class_name)).new(data).tap do |wrapper|
            cleaned_options = options.dup
            
            fill = cleaned_options.delete(:fill)
            fill = case fill
                   when Array then fill
                   when Symbol then [fill]
                   else
                     []
                   end
            fill.each { |field|
              wrapper.__send__("#{field}=", wrap(data[field], cleaned_options))
            }
          end
        else
          data
        end
      end
    end

    def batch(&block)
      b = Batch.new(self.class)
      b[self.id]
      if block_given?
        yield(b).commit
      else
        b
      end
    end
  end
end
