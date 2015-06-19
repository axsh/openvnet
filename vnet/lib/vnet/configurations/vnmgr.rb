# -*- coding: utf-8 -*-

module Vnet::Configurations
  class Vnmgr < Common
    class Node < Fuguta::Configuration
      param :id, :default => "vnmgr"
      param :plugins, :default => []

      class Addr < Fuguta::Configuration
        param :protocol, :default => "tcp"
        param :host, :default => "127.0.0.1"
        param :public, :default => ""
        param :port, :default => 9102
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

    param :datapath_broadcast_mac_vendor_address, :default => [0x02, 0xbe, 0xef]

    def validate(errors)
      v = @config[:datapath_broadcast_mac_vendor_address]
      case v
      when Array
        if v.size != 3
          raise "datapath_broadcast_mac_vendor_address: invalid length"
        end
      else
        raise "datapath_broadcast_mac_vendor_address: invalid value"
      end
    end
  end
end
