# -*- coding: utf-8 -*-

require 'dcell'

module Vnmgr::StorageBackends
  class DCellWrapper
    attr_reader :table_name

    def initialize(dba_conf, table_name)
      @@dcell ||= DCell::Node[dba_conf.cluster_name][dba_conf.node_name]
      @table_name ||= table_name
    end

    def method_missing(method_name, *args)
      ret = dcell.send(method_name, table_name, *args)
      wrapping(ret)
    end

    private
    def wrapping(data)
      case data
      when Array
        data.map{|r| Vnmgr::ModelWrappers.const_get("#{table_name.capitalize}Wrapper").new(r) }
      when nil
        nil
      else
        Vnmgr::ModelWrappers.const_get("#{table_name.capitalize}Wrapper").new(data)
      end
    end

    def dcell
      @@dcell
    end
  end

  class DBA < Vnmgr::StorageBackend

    def initialize(vnmgr_conf, dba_conf, common_conf)
      #TODO: Make these configuration keys more generic so they can be used in other places than vnmgr
      DCell.me || DCell.start(:id => vnmgr_conf.cluster_name, :addr => "tcp://#{vnmgr_conf.ip}:#{vnmgr_conf.port}",
      :registry => {
        :adapter => 'redis',
        :host => common_conf.redis_host,
        :port => common_conf.redis_port
      })

      [:network, :vif, :dhcp_range, :mac_range, :mac_lease, :router, :tunnel, :dc_network, :datapath, :open_flow_controller, :ip_address, :ip_lease].each do |klass_name|
        # instantiation
        c = DCellWrapper.new(dba_conf, klass_name)
        instance_variable_set("@#{klass_name}", c)

        # method definition
        define_singleton_method klass_name do
          instance_variable_get("@#{klass_name}")
        end
      end
    end
  end
end

