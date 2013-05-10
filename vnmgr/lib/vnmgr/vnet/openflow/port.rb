# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  class Port
    attr_reader :datapath
    attr_reader :port_info
    # attr_reader :lock

    attr_reader :is_active

    def initialize dp, port_info, active
      @datapath = dp
      @port_info = port_info
      # @lock = Mutex.new

      @is_active = active
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

    # def init_gre_tunnel(network)
    #   @port_type = PORT_TYPE_TUNNEL
    #   queue_flow Flow.new(TABLE_CLASSIFIER, 8, {:in_port => port_info.number}, [{:load_reg1 => network.id, :load_reg2 => port_info.number}, {:resubmit => TABLE_VIRTUAL_SRC}])
    # end

    # def init_instance_subnet(network, eth_port, hw, ip)
    #   queue_flow Flow.new(TABLE_CLASSIFIER, 8, {:in_port => eth_port, :dl_dst => hw}, {:load_reg1 => network.id, :load_reg2 => eth_port, :resubmit => TABLE_VIRTUAL_SRC})
    # end

  end

end
