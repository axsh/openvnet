
# -*- coding: utf-8 -*-

module Vnmgr::Configurations
  class Vna < Common
    class Node < Fuguta::Configuration
      param :id, :default => "vna"

      class Addr < Fuguta::Configuration
        param :protocol, :default => "tcp"
        param :host, :default => "127.0.0.1"
        param :port, :default => 9103
      end

      DSL do
        def addr(&block)
          @config[:addr] = Addr.new.tap {|c| c.parse_dsl(&block) if block }
          @config[:addr_string] = "#{@config[:addr].protocol}://#{@config[:addr].host}:#{@config[:addr].port}"
        end
      end
    end

    DSL do
      def node(&block)
        @config[:node] = Node.new.tap {|node| node.parse_dsl(&block) if block }
      end
    end

    param :dba_node_id, :default => "dba"
    param :dba_actor_name, :default => "dba"
    param :data_access_proxy, :default => :dba
  end
end
