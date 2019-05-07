# -*- coding: utf-8 -*-

module Vnet
  module NodeApi
    class RpcProxy < Proxy
      protected

      class RpcCall < Call
        def initialize(class_name)
          super

          tries = 0

          while true
            tries += 1

            rpc_node = DCell::Node['vnmgr']

            if rpc_node == nil
              Celluloid.logger.debug "node 'vnmgr' not found, retrying" if (tries % 10) == 1
              sleep 1
              next
            end

            @actor = rpc_node[:rpc]

            if rpc_node == nil
              Celluloid.logger.debug "node 'vnmgr' has no rpc actor, retrying" if (tries % 10) == 1
              sleep 1
              next
            end

            return
          end
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
