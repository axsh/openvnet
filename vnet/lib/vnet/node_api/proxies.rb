# -*- coding: utf-8 -*-
module Vnet::NodeApi
  class Proxy
    def method_missing(class_name, *args, &block)
      if class_name.present? && args.empty? && Vnet::NodeApi.const_defined?(class_name.to_s.camelize)
        _call_class.new(class_name).tap do |call|
          define_singleton_method(class_name){ call }
        end
      else
        super
      end
    end

    protected
    def _call_class
      raise "Not implemented"
    end

    class Call
      def initialize(class_name)
        @class_name = class_name
      end

      def method_missing(method_name, *args, &block)
        _call(method_name, *args, &block)
      rescue => exception
        raise exception if Vnet::NodeApi.raise_on_error
        logger.debug("#{exception.class}: #{exception.to_s}\n\t")
        logger.debug(exception.backtrace.join("\n\t"))
      end

      private

      def _call(method_name, *args, &block)
      end

      def logger
        Vnet::NodeApi.logger
      end
    end
  end

  class RpcProxy < Proxy
    protected
    class RpcCall < Call
      def initialize(class_name)
        super
        @actor = DCell::Global[:rpc] or raise "rpc not found in DCell::Global"
      end

      def _call(method_name, *args, &block)
        @actor.execute(@class_name, method_name, *args, &block)
      end
    end

    def _call_class
      RpcCall
    end
  end

  class DirectProxy < Proxy
    protected
    class DirectCall < Call
      def initialize(class_name)
        super
        @method_caller = Vnet::NodeApi.const_get(class_name.to_s.camelize)
      end

      def _call(method_name, *args, &block)
        @method_caller.send(method_name, *args, &block)
      end
    end

    def _call_class
      DirectCall
    end
  end
end
