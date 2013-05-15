# -*- coding: utf-8 -*-

require 'dcell'

module Vnmgr::StorageBackends
  class DBA < Vnmgr::StorageBackend
    def initialize(conf)
      #TODO: Make these configuration keys more generic so they can be used in other places than vnmgr
      DCell.me || DCell.start(:id => conf.cluster_name, :addr => "tcp://#{conf.vnmgr_agent_ip}:#{conf.vnmgr_agent_port}",
      :registry => {
        :adapter => 'redis',
        :host => conf.redis_host,
        :port => conf.redis_port
      })

      ['Network','Vif'].each do |m|
        # class definition
        self.class.const_set(m, Class.new {
          attr_reader :dcell

          def initialize
            @dcell = DCell::Node['vnmgr'][dcell_node_name]
          end

          def method_missing(method_name, *args)
            ret = dcell.send(method_name, args)
            p ret
            # case ret
            # when Array
            #   ret.map{|r| Vnmgr::ModelWrappers.const_get(r["wrapper_class"]).new(r) }
            # when nil
            #   nil
            # else
            #   Vnmgr::ModelWrappers.const_get(ret["wrapper_class"]).new(ret)
            # end
          end

          private
          def dcell_node_name
            self.class.to_s.split('::').last.downcase
          end
        })

        # instantiation
        c = self.class.const_get(m).new
        instance_variable_set("@#{m.downcase}_dcell_node", c)

        # method definition
        define_singleton_method m.downcase do
          instance_variable_get("@#{m.downcase}_dcell_node")
        end
      end
    end
  end
end

