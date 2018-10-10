# -*- coding: utf-8 -*-
module Vnet::NodeApi
  class Proxy
    def method_missing(class_name, *args, &block)
      # The const_defined search constructs all the NodeApi::*
      # classes, even if we are using 'rpc', and as such can't do a
      # search to validate the class names.
      if class_name.present? && args.empty?
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
        nil
      end

      private

      def _call(method_name, *args, &block)
      end

      def logger
        Vnet.logger
      end
    end
  end

  class RpcProxy < Proxy
    protected
    class RpcCall < Call
      def initialize(class_name)
        super

        rpc_node_id = DCell::Global[:rpc_node_id] or raise "rpc_node_id not found in DCell::Global"
        raise "tried to use non-string rpc_node_id '#{rpc_node_id.inspect}'" if !rpc_node_id.is_a? String

        rpc_node = DCell::Node[rpc_node_id] or raise "node '#{rpc_node_id}' with rpc not found"

        @actor = rpc_node[:rpc] or raise "rpc actor on node '#{rpc_node_id}' not found"
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
