# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  class Network
    include Constants

    attr_reader :datapath
    attr_reader :network_id
    attr_reader :network_number
    attr_reader :uuid
    attr_reader :ports

    def initialize(dp, nw_id, uuid)
      @datapath = dp
      @network_id = nw_id
      @network_number = nw_id
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

  end

end
