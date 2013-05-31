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

    def commit
      @model.execute_batch(*@methods)
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
        klass = _proxy.send(self.name.demodulize.underscore.to_sym)
        wrap(klass.send(method_name, *args, &block))
      end

      protected
      def wrap(data)
        case data
        when Array
          data.map{|d| ::Vnmgr::ModelWrappers.const_get(d.delete(:class_name)).new(d) }
        when Hash
          ::Vnmgr::ModelWrappers.const_get(data.delete(:class_name)).new(data)
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
