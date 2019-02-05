# -*- coding: utf-8 -*-

module Vnet
  module NodeApi
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
  end
end
