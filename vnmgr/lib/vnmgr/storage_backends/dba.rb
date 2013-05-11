# -*- coding: utf-8 -*-

require 'dcell'

module Vnmgr::StorageBackends
  class DCellConnection
    attr_reader :dcell, :class_name

    def initialize(name)
      @dcell = DCell::Node['vnmgr'][name]
      @class_name = name
    end

    def method_missing(method_name, *args)
      ret = dcell.entry(method_name, args[0])
      wrapping(ret)
    end

    private
    def wrapping(data)
      case data
      when Array
        data.map{|r| Vnmgr::ModelWrappers.const_get("#{class_name.capitalize}Wrapper").new(r) }
      when nil
        nil
      else
        Vnmgr::ModelWrappers.const_get("#{class_name.capitalize}Wrapper").new(data)
      end
    end
  end

  class DBA < Vnmgr::StorageBackend

    def initialize(conf)
      #TODO: Make these configuration keys more generic so they can be used in other places than vnmgr
      DCell.me || DCell.start(:id => conf.cluster_name, :addr => "tcp://#{conf.vnmgr_agent_ip}:#{conf.vnmgr_agent_port}",
      :registry => {
        :adapter => 'redis',
        :host => conf.redis_host,
        :port => conf.redis_port
      })

      #TODO: port the following array to config file.
      [:network, :vif, :dhcp_range, :mac_range, :mac_lease, :router, :tunnel, :dc_network, :datapath, :open_flow_controller, :ip_address, :ip_lease].each do |klass_name|
        # instantiation
        c = DCellConnection.new(klass_name)
        instance_variable_set("@#{klass_name}", c)

        # method definition
        define_singleton_method klass_name do
          instance_variable_get("@#{klass_name}")
        end
      end
    end
  end
end

