# -*- coding: utf-8 -*-

module Vnet::Openflow

  # Thread-safe access to static information on the datapath and
  # managers / actors. No writes are done to this instance after the
  # creation of the datapath.
  #
  # Since this isn't an actor we avoid the need to go through
  # Datapath's thread for every time we use a manager.
  class DpInfo
    attr_reader :controller
    attr_reader :datapath

    attr_reader :dpid
    attr_reader :dpid_s
    attr_reader :ovs_ofctl

    attr_reader :cookie_manager
    attr_reader :dc_segment_manager
    attr_reader :interface_manager
    attr_reader :network_manager
    attr_reader :packet_manager
    attr_reader :port_manager
    attr_reader :route_manager
    attr_reader :service_manager
    attr_reader :tunnel_manager
    attr_reader :translation_manager

    def initialize(params)
      @dpid = params[:dpid]
      @dpid_s = "0x%016x" % @dpid

      @controller = params[:controller]
      @datapath = params[:datapath]
      @ovs_ofctl = params[:ovs_ofctl]

      @cookie_manager = CookieManager.new
      @dc_segment_manager = DcSegmentManager.new(@datapath)
      @interface_manager = InterfaceManager.new(self)
      @network_manager = NetworkManager.new(self)
      @packet_manager = PacketManager.new(@datapath)
      @port_manager = PortManager.new(self)
      @route_manager = RouteManager.new(@datapath)
      @service_manager = ServiceManager.new(self)
      @tunnel_manager = TunnelManager.new(@datapath)
      @translation_manager = TranslationManager.new(self)
    end

    #
    # Flow modification:
    #

    def add_flow(flow)
      @controller.pass_task {
        @controller.send_flow_mod_add(@dpid, flow.to_trema_hash)
      }
    end

    def add_flows(flows)
      return if flows.blank?
      @controller.pass_task {
        flows.each { |flow|
          @controller.send_flow_mod_add(@dpid, flow.to_trema_hash)
        }
      }
    end

    def add_ovs_flow(flow_str)
      @ovs_ofctl.add_ovs_flow(flow_str)
    end

    def add_ovs_10_flow(flow_str)
      @ovs_ofctl.add_ovs_10_flow(flow_str)
    end

    def del_cookie(cookie, cookie_mask = 0xffffffffffffffff)
      options = {
        :command => Controller::OFPFC_DELETE,
        :table_id => Controller::OFPTT_ALL,
        :out_port => Controller::OFPP_ANY,
        :out_group => Controller::OFPG_ANY,
        :cookie => cookie,
        :cookie_mask => cookie_mask
      }

      @controller.pass_task {
        @controller.public_send_flow_mod(@dpid, options)
      }
    end

    #
    # Trema messaging:
    #

    def send_message(message)
      @controller.pass_task {
        @controller.public_send_message(@dpid, message)
      }
    end

    def send_packet_out(message, port_no)
      @controller.pass_task {
        @controller.public_send_packet_out(@dpid, message, port_no)
      }
    end

  end

end
