# -*- coding: utf-8 -*-

module Vnet
  module NodeApi
    class RpcProxy < Proxy
      protected

      class RpcCall < Call
        def initialize(class_name)
          super

          @actor = nil
        end

        def _call(method_name, *args, &block)
          #### Move initialize to here.

          # TODO: Catch dead actors, look up / wait for new node/actor.

          while true
            begin
              if @actor && @actor.alive?
                return @actor.execute(@class_name, method_name, *args, &block)
              end
            rescue Celluloid::DeadActorError
            end

            Celluloid.logger.debug "MMMMMMMMMMMMMMMMMMMMMMMM"
            @actor = get_rpc_actor
          end
        end

        private

        def get_rpc_actor
          while true
            DCell::Global[:rpc_node_id].tap { |rpc_node_id|
              next if rpc_node_id.nil?
              rpc_node = DCell::Node[rpc_node_id]
              next if rpc_node.nil?
              rpc_actor = rpc_node[:rpc]
              return rpc_actor if rpc_actor && rpc_actor.alive?
            }
            
            Celluloid.logger.debug "XXXXXXXXXXXXXXXXXX"

            sleep(5)
          end
        end

      end

      def _call_class
        RpcCall
      end
    end
  end
end
