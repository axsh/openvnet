# -*- coding: utf-8 -*-

module Vnet
  module DataAccess
    def self.get_proxy(conf)
      case conf.data_access_proxy
      when :dba
        DbaProxy.new(conf)
      when :direct
        DirectProxy.new(conf)
      else
        raise "Unknown proxy: #{conf.data_access_proxy}"
      end
    end
  end
end
