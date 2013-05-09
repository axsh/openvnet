# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  # OpenFlow datapath allows us to send OF messages and ovs-ofctl
  # commands to a specific bridge/switch.
  class Datapath
    attr_reader :controller
    attr_reader :datapath_id
    attr_reader :ovs_ofctl

    def initialize ofc, dp_id, ofctl = nil
      @controller = ofc
      @datapath_id = dp_id
      @ovs_ofctl = ofctl
    end

    def switch
      self.controller.switches[self.datapath_id]
    end

    def add_flow(flow)
      self.controller.send_flow_mod_add(self.datapath_id, flow.to_trema_flow)
    end

    def add_flows(flows)
      flows.each { |flow| self.controller.send_flow_mod_add(self.datapath_id, flow.to_trema_flow) }
    end

    def send_message(message)
      self.controller.public_send_message(self.datapath_id, message)
    end

  end

end
