# -*- coding: utf-8 -*-

module Vnet::Openflow

  # OpenFlow datapath allows us to send OF messages and ovs-ofctl
  # commands to a specific bridge/switch.
  class Datapath
    attr_reader :controller
    attr_reader :dpid
    attr_reader :ovs_ofctl
    attr_accessor :switch

    def initialize(ofc, dp_id, ofctl = nil)
      @controller = ofc
      @dpid = dp_id
      @ovs_ofctl = ofctl
    end

    def inspect
      "<##{self.class.name} dpid:#{@dpid}>"
    end

    def add_flow(flow)
      self.controller.pass_task { self.controller.send_flow_mod_add(self.dpid, flow) }
    end

    def add_ovs_flow(flow_str)
      self.ovs_ofctl.add_ovs_flow(flow_str)
    end

    # def del_flow(flow)
    #   self.controller.pass_task { self.controller.public_send_flow_mod(self.dpid,
    #                                                                    flow.merge(:command => Controller::OFPFC_DELETE))
    #   }
    # end

    def del_cookie(cookie)
      options = {
        :command => Controller::OFPFC_DELETE,
        :table_id => Controller::OFPTT_ALL,
        :out_port => Controller::OFPP_ANY,
        :out_group => Controller::OFPG_ANY,
        :cookie => cookie,
        :cookie_mask => 0xffffffffffffffff
      }

      self.controller.pass_task { self.controller.public_send_flow_mod(self.dpid, options) }
    end

    def add_flows(flows)
      return if flows.blank?
      self.controller.pass_task {
        flows.each { |flow|
          self.controller.send_flow_mod_add(self.dpid, flow)
        }
      }
    end

    def send_message(message)
      self.controller.pass_task { self.controller.public_send_message(self.dpid, message) }
    end

    def send_packet_out(message, port_no)
      self.controller.pass_task { self.controller.public_send_packet_out(self.dpid, message, port_no) }
    end

    def add_tunnel(tunnel_name, remote_ip)
      self.ovs_ofctl.add_tunnel(tunnel_name, remote_ip)
    end
  end

end
