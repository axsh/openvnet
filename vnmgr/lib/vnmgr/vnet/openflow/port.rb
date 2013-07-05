# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  class Port
    include Celluloid::Logger

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

      @cookie = self.port_number | (0x3 << 48)
    end

    def port_number
      self.port_info.port_no
    end

    def port_name
      self.port_info.name
    end

    def network_number
      if self.network
        self.network.network_number
      else
        0x0
      end
    end

    def eth?
      false
    end

    def tunnel?
      false
    end

    def inspect
      str = "<"
      str << "@port_info=#{@port_info.inspect}, "
      str << "@port_type=#{@port_type.inspect}, "
      str << "@is_active=#{@is_active.inspect}>"
      str
    end

    def metadata_p(port = self.port_number)
      { :metadata => port,
        :metadata_mask => Constants::METADATA_PORT_MASK
      }
    end

    def metadata_n(nw = self.network_number)
      { :metadata => nw << Constants::METADATA_NETWORK_SHIFT,
        :metadata_mask => Constants::METADATA_NETWORK_MASK
      }
    end

    def metadata_np(nw = self.network_number, port = self.port_number)
      { :metadata => (nw << Constants::METADATA_NETWORK_SHIFT) | port,
        :metadata_mask => (Constants::METADATA_PORT_MASK | Constants::METADATA_NETWORK_MASK)
      }
    end

    def flow_options_load_port(goto_table)
      flow_options.merge({ :metadata => self.port_number,
                           :metadata_mask => Constants::METADATA_PORT_MASK,
                           :goto_table => goto_table
                         })
    end

    def flow_options_load_network(goto_table, extra_metadata = 0x0, extra_mask = 0x0)
      flow_options.merge({ :metadata => (self.network_number << Constants::METADATA_NETWORK_SHIFT) | extra_metadata,
                           :metadata_mask => Constants::METADATA_NETWORK_MASK | extra_mask,
                           :goto_table => goto_table
                         })
    end

    def flow_options_load_np(goto_table)
      flow_options_load_network(goto_table, self.port_number, Constants::METADATA_PORT_MASK)
    end

    def install
      error "port: No install action implemented for this port."
    end

    def uninstall
      debug "port: Removing flows..."

      self.datapath.del_cookie(@cookie)
    end

    def update_eth_ports
    end

    def update_tunnel_ports
    end
  end

end
