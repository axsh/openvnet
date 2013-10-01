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
      @port_manager = PortManager.new(@datapath)
      @route_manager = RouteManager.new(@datapath)
      @service_manager = ServiceManager.new(self)
      @tunnel_manager = TunnelManager.new(@datapath)
    end

  end

end
