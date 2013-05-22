# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  # OpenFlow datapath allows us to send OF messages and ovs-ofctl
  # commands to a specific bridge/switch.
  class Datapath
    attr_reader :controller
    attr_reader :datapath_id
    attr_reader :ovs_ofctl

    def initialize(ofc, dp_id, ofctl = nil)
      @controller = ofc
      @datapath_id = dp_id
      @ovs_ofctl = ofctl
    end

    def switch
      self.controller.switches[self.datapath_id]
    end

    def add_flow(flow)
      if Thread.current == self.controller.trema_thread
        self.controller.send_flow_mod_add(self.datapath_id, flow)
      else
        self.controller.pass_task { self.controller.send_flow_mod_add(self.datapath_id, flow) }
      end
    end

    def del_flow(flow)
      if Thread.current == self.controller.trema_thread
        self.controller.public_send_flow_mod(self.datapath_id, flow.merge(:command => Controller::OFPFC_DELETE))
      else
        self.controller.pass_task { self.controller.public_send_flow_mod(self.datapath_id, flow.merge(:command => Controller::OFPFC_DELETE)) }
      end
    end

    def add_flows(flows)
      if Thread.current == self.controller.trema_thread
        flows.each { |flow|
          self.controller.send_flow_mod_add(self.datapath_id, flow)
        }
      else
        self.controller.pass_task {
          flows.each { |flow|
            self.controller.send_flow_mod_add(self.datapath_id, flow)
          }
        }
      end
    end

    def send_message(message)
      if Thread.current == self.controller.trema_thread
        self.controller.public_send_message(self.datapath_id, message)
      else
        self.controller.pass_task { self.controller.public_send_message(self.datapath_id, message) }
      end
    end

  end

end
