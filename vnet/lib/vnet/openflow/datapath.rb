# -*- coding: utf-8 -*-

module Vnet::Openflow

  # OpenFlow datapath allows us to send OF messages and ovs-ofctl
  # commands to a specific bridge/switch.
  class Datapath
    include Celluloid
    include Celluloid::Logger
    include FlowHelpers

    attr_reader :controller
    attr_reader :dpid
    attr_reader :ovs_ofctl

    # Do not update any values of the datapath db for outside of the
    # Datapath actor.
    attr_reader :datapath_map

    attr_reader :switch

    attr_reader :cookie_manager
    attr_reader :dc_segment_manager
    attr_reader :network_manager
    attr_reader :packet_manager
    attr_reader :route_manager
    attr_reader :tunnel_manager

    def initialize(ofc, dp_id, ofctl = nil)
      @controller = ofc
      @dpid = dp_id
      @ovs_ofctl = ofctl

      @cookie_manager = CookieManager.new
      @dc_segment_manager = DcSegmentManager.new(self)
      @network_manager = NetworkManager.new(self)
      @packet_manager = PacketManager.new(self)
      @route_manager = RouteManager.new(self)
      @tunnel_manager = TunnelManager.new(self)

      @cookie_manager.create_category(:collection,     COOKIE_PREFIX_COLLECTION)
      @cookie_manager.create_category(:dp_network,     COOKIE_PREFIX_DP_NETWORK)
      @cookie_manager.create_category(:network,        COOKIE_PREFIX_NETWORK)
      @cookie_manager.create_category(:packet_handler, COOKIE_PREFIX_PACKET_HANDLER)
      @cookie_manager.create_category(:port,           COOKIE_PREFIX_PORT)
      @cookie_manager.create_category(:route,          COOKIE_PREFIX_ROUTE)
      @cookie_manager.create_category(:route_link,     COOKIE_PREFIX_ROUTE_LINK)
      @cookie_manager.create_category(:switch,         COOKIE_PREFIX_SWITCH)
      @cookie_manager.create_category(:tunnel,         COOKIE_PREFIX_TUNNEL)
      @cookie_manager.create_category(:vif,            COOKIE_PREFIX_VIF)

      @packet_manager.insert(Vnet::Openflow::Services::Arp.new(:datapath => self), :arp)
      @packet_manager.insert(Vnet::Openflow::Services::Icmp.new(:datapath => self), :icmp)
    end

    def datapath_batch
      @datapath_map.batch
    end

    def inspect
      "<##{self.class.name} dpid:#{@dpid}>"
    end

    def ipv4_address
      ipv4_value = @datapath_map.ipv4_address
      ipv4_value && IPAddr.new(ipv4_value, Socket::AF_INET)
    end

    def create_switch
      @switch = Switch.new(self)
      @switch.create_default_flows

      @datapath_map = MW::Datapath[:dpid => ("0x%016x" % @dpid)]

      if @datapath_map.nil
        warn "datapath: could not find dpid (0x%016x)" % @dpid if @datapath_map.nil?
        return
      end

      @switch.switch_ready
    end

    #
    # Flow modification methods:
    #

    def add_flow(flow)
      @controller.pass_task { @controller.send_flow_mod_add(@dpid, flow) }
    end

    def add_ovs_flow(flow_str)
      @ovs_ofctl.add_ovs_flow(flow_str)
    end

    def add_ovs_10_flow(flow_str)
      @ovs_ofctl.add_ovs_10_flow(flow_str)
    end

    def del_cookie(cookie)
      options = {
        :command => Controller::OFPFC_DELETE,
        :table_id => Controller::OFPTT_ALL,
        :out_port => Controller::OFPP_ANY,
        :out_group => Controller::OFPG_ANY,
        :cookie => cookie,
        :cookie_mask => 0xffffffffffffffff
      }

      @controller.pass_task { @controller.public_send_flow_mod(@dpid, options) }
    end

    def add_flows(flows)
      return if flows.blank?
      @controller.pass_task {
        flows.each { |flow|
          @controller.send_flow_mod_add(@dpid, flow)
        }
      }
    end

    def send_message(message)
      @controller.pass_task { @controller.public_send_message(@dpid, message) }
    end

    def send_packet_out(message, port_no)
      @controller.pass_task { @controller.public_send_packet_out(@dpid, message, port_no) }
    end

    #
    # Port modification methods:
    #

    def mod_port(port_no, action)
      debug "datapath: modifying port_number:#{port_no} action:#{action.to_s}"
      @ovs_ofctl.mod_port(port_no, action)
    end

    def add_tunnel(tunnel_name, remote_ip)
      @ovs_ofctl.add_tunnel(tunnel_name, remote_ip)
    end

    def delete_tunnel(tunnel_name)
      debug "datapath: delete tunnel #{tunnel_name}"
      self.ovs_ofctl.delete_tunnel(tunnel_name)
    end

  end

end
