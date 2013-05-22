# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  class Network
    include Constants

    attr_reader :datapath
    attr_reader :network_id
    attr_reader :uuid
    attr_reader :ports

    def initialize(dp, nw_id, uuid)
      @datapath = dp
      @network_id = nw_id
      @uuid = uuid
      @ports = {}
    end

    def add_port(port)
      raise("Port already added to a network.") if port.network || self.ports[port.port_number]

      self.ports[port.port_number] = port
      port.network = self

      update_flows
    end

    def del_port(port)
      deleted_port = self.ports.delete(port.port_number)
      update_flows

      raise("Port not added to this network.") if port.network != self || deleted_port.nil?

      port.network = nil
    end

    def install
      flows = []
      flows << Flow.create(TABLE_PHYSICAL_DST, 1, {:eth_dst => Trema::Mac.new('ff:ff:ff:ff:ff:ff')}, {},
                           {:cookie => OFPP_FLOOD | 0x100000000, :metadata => OFPP_FLOOD, :metadata_mask => 0xffffffff, :goto_table => TABLE_PHYSICAL_SRC})

      self.datapath.add_flows(flows)
    end

    def update_flows
      flood_actions = ports.collect { |key,port| {:output => port.port_number} }

      flows = []
      flows << Flow.create(TABLE_METADATA_ROUTE, 0, {:metadata => OFPP_FLOOD, :metadata_mask => 0xffffffff}, flood_actions,
                           {:cookie => OFPP_FLOOD | 0x100000000})

      self.datapath.add_flows(flows)
    end

  end

end
