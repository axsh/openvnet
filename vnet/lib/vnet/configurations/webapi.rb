
# -*- coding: utf-8 -*-

module Vnet::Configurations
  class Webapi < Common
    class Node < Fuguta::Configuration
      param :id, :default => "webapi"

      class Addr < Fuguta::Configuration
        param :protocol, :default => "tcp"
        param :host, :default => "127.0.0.1"
        param :public, :default => ""
        param :port, :default => 9101
      end

      DSL do
        def addr(&block)
          @config[:addr] = Addr.new.tap {|c| c.parse_dsl(&block) if block }
          @config[:addr_string] = "#{@config[:addr].protocol}://#{@config[:addr].host}:#{@config[:addr].port}"
          @config[:pub_addr_string] = "#{@config[:addr].protocol}://#{@config[:addr].public}:#{@config[:addr].port}"
        end
      end
    end

    DSL do
      def node(&block)
        @config[:node] = Node.new.tap {|node| node.parse_dsl(&block) if block }
      end
    end

    param :node_api_proxy, :default => :direct
    param :pagination_limit, :default => 30
  end
end
