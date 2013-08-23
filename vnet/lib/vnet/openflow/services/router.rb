# -*- coding: utf-8 -*-

require 'racket'

module Vnet::Openflow::Services

  class Router < Base
    attr_reader :network_id
    attr_reader :interface_uuid
    attr_reader :service_mac
    attr_reader :service_ipv4

    def initialize(params)
      super
      @network_id = params[:network_id]
      @network_uuid = params[:network_uuid]
      @interface_uuid = params[:interface_uuid]
      @service_mac = params[:service_mac]
      @service_ipv4 = params[:service_ipv4]

      @routes = {}
    end

    def install
      debug "service::router.install: network:#{@network_uuid} interface_uuid:#{@interface_uuid.inspect} mac:#{@service_mac} ipv4:#{@service_ipv4}"
    end

  end

end
