# -*- coding: utf-8 -*-

module Vnet::Configurations
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

    class SecurityGroups < Fuguta::Configuration
      param :enabled, :default => true
      param :log_connection_tracking, :default => false
    end

    # The initialize hook makes sure the default configs for security groups are
    # still accessible even when there is no security_groups block in vna.conf
    on_initialize_hook { @config[:security_groups] = SecurityGroups.new }
    DSL do
      def security_groups(&block)
        @config[:security_groups] = SecurityGroups.new.tap { |sg|
          sg.parse_dsl(&block) if block
        }
      end
    end

    param :node_api_proxy, :default => :rpc
    param :trema_home, :default => Gem::Specification.find_by_name('trema').gem_dir
    param :trema_tmp, :default => '/var/run/wakame-vnet'
  end

end
