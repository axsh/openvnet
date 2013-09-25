# -*- coding: utf-8 -*-

module Vnet::Openflow::Ports

  class Base
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_reader :port_info

    def initialize(dp, port_info)
      @datapath = dp
      @port_info = port_info

      @cookie = self.port_number | (COOKIE_PREFIX_PORT << COOKIE_PREFIX_SHIFT)
    end

    def port_number
      @port_info.port_no
    end

    def port_name
      @port_info.name
    end

    def port_hw_addr
      @port_info.hw_addr
    end

    def port_type
      :unknown
    end

    def to_hash
      { :port_number => self.port_number,
        :port_hw_addr => self.port_hw_addr,
        :name => self.port_name,
        :type => self.port_type,
        :ipv4_address => @ipv4_addr,
        :network_id => @network_id,
      }
    end

    def inspect
      str = "<"
      str << "@port_info=#{@port_info.inspect}, "
      str << "@port_type=#{@port_type.inspect}, "
      str << "@is_active=#{@is_active.inspect}>"
      str
    end

    def install
      error "port: No install action implemented for this port."
    end

    def uninstall
      debug "port: Removing flows..."

      @datapath.del_cookie(@cookie)
    end

  end

end
