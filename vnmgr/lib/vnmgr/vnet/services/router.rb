# -*- coding: utf-8 -*-

require 'racket'

module Vnmgr::VNet::Services

  class Router < Vnmgr::VNet::Openflow::PacketHandler
    attr_reader :network
    attr_reader :vif_uuid
    attr_reader :service_mac
    attr_reader :service_ipv4

    def initialize(params)
      @datapath = params[:datapath]
      @network = params[:network]
      @vif_uuid = params[:vif_uuid]
      @service_mac = params[:service_mac]
      @service_ipv4 = params[:service_ipv4]
    end

    def install
    end

    def packet_in(port, message)
      debug "Router.packet_in called."
    end

  end

end
