# -*- coding: utf-8 -*-

module Vnet
  module NodeApi
    class RpcProxy < Proxy
      protected

      class RpcCall < Call
        def initialize(class_name)
          super

          @actor = Vnet::get_node_actor('vnmgr', :rpc)
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
