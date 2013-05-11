# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  class Port
    attr_reader :datapath
    attr_reader :port_info
    attr_reader :is_active
    attr_accessor :network

    def initialize dp, port_info, active
      @datapath = dp
      @port_info = port_info

      @is_active = active
    end

    def port_number
      self.port_info.port_no
    end

    def inspect
      str = "<"
      str << "@port_info=#{@port_info.inspect}, "
      str << "@port_type=#{@port_type.inspect}, "
      str << "@is_active=#{@is_active.inspect}>"
      str
    end

    def flow_options_load_port(goto_table)
      flow_options.merge({:metadata => port_info.port_no, :metadata_mask => 0xffffffff, :goto_table => goto_table})
    end

    def install
      p "port: No install action implemented for this port."
    end

  end

end
