# -*- coding: utf-8 -*-

module Vnet::Openflow

  # OpenFlow datapath allows us to send OF messages and ovs-ofctl
  # commands to a specific bridge/switch.
  class Datapath
    attr_reader :controller
    attr_reader :datapath_id
    attr_reader :ovs_ofctl
    attr_accessor :switch

    def initialize(ofc, dp_id, ofctl = nil)
      @controller = ofc
      @datapath_id = dp_id
      @ovs_ofctl = ofctl
    end

    def inspect
      "<##{self.class.name} datapath_id:#{@datapath_id}>"
    end

    def add_flow(flow)
      self.controller.pass_task { self.controller.send_flow_mod_add(self.datapath_id, flow) }
    end

    def add_ovs_flow(flow_str)
      self.ovs_ofctl.add_ovs_flow(flow_str)
    end

    # def del_flow(flow)
    #   self.controller.pass_task { self.controller.public_send_flow_mod(self.datapath_id,
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

      self.controller.pass_task { self.controller.public_send_flow_mod(self.datapath_id, options) }
    end

    def add_flows(flows)
      return if flows.blank?
      self.controller.pass_task {
        flows.each { |flow|
          self.controller.send_flow_mod_add(self.datapath_id, flow)
        }
      }
    end

    def send_message(message)
      self.controller.pass_task { self.controller.public_send_message(self.datapath_id, message) }
    end

    def send_packet_out(message, port_no)
      self.controller.pass_task { self.controller.public_send_packet_out(self.datapath_id, message, port_no) }
    end

    def add_tunnel(tunnel_name, remote_ip)
      self.ovs_ofctl.add_tunnel(tunnel_name, remote_ip)
    end

    def delete_tunnel(tunnel_name)
      self.ovs_ofctl.delete_tunnel(tunnel_name)
    end
  end

end
