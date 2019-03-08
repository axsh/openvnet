# -*- coding: utf-8 -*-

module Vnet
  module NodeApi
    class RpcProxy < Proxy
      protected
      class RpcCall < Call
        def initialize(class_name)
          super

          # Call 'redis-cli FLUSHALL' if this fails with 'node_id not found'.
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
  end
end
