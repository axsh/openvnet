# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  class Port
    attr_reader :datapath
    attr_reader :port_info
    attr_reader :is_active

    attr_accessor :hw_addr
    attr_accessor :ipv4_addr
    attr_accessor :network

    def initialize(dp, port_info, active)
      @datapath = dp
      @port_info = port_info

      @is_active = active
    end

    def port_number
      self.port_info.port_no
    end

    def network_number
      if self.network
        self.network.network_number
      else
        0x0
      end
    end

    def is_eth_port
      false
    end

    def inspect
      str = "<"
      str << "@port_info=#{@port_info.inspect}, "
      str << "@port_type=#{@port_type.inspect}, "
      str << "@is_active=#{@is_active.inspect}>"
      str
    end

    def flow_options_load_port(goto_table)
      flow_options.merge({:metadata => self.port_number, :metadata_mask => 0xffffffff, :goto_table => goto_table})
    end

    def flow_options_load_network(goto_table)
      flow_options.merge({ :metadata => self.network_number << Constants::METADATA_NETWORK_SHIFT,
                           :metadata_mask => Constants::METADATA_NETWORK_MASK,
                           :goto_table => goto_table
                         })
    end

    def install
      p "port: No install action implemented for this port."
    end

    def uninstall
      p "port: Removing flows..."

      self.datapath.del_flow(flow_options)
    end

  end

end
