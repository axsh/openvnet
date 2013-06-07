# -*- coding: utf-8 -*-

module Vnmgr::Configurations
  class Dba < Common
    class Node < Fuguta::Configuration
      param :id, :default => "dba"

      class Addr < Fuguta::Configuration
        param :protocol, :default => "tcp"
        param :host, :default => "127.0.0.1"
        param :port, :default => 9102
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

    DSL do
      def actor_names(*names)
        @config[:actor_names] ||={}
        @config[:actor_names] = names
      end
    end
    param :actor_names, :default => %w(dba)
  end
end
