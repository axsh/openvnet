# -*- coding: utf-8 -*-

module Vnet::Openflow::Networks

  class Base < Vnet::ItemDpUuid
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_reader :cookie
    attr_reader :ipv4_network
    attr_reader :ipv4_prefix

    def initialize(params)
      super

      map = params[:map]

      @cookie = @id | COOKIE_TYPE_NETWORK
      @ipv4_network = IPAddr.new(map.ipv4_network, Socket::AF_INET)
      @ipv4_prefix = map.ipv4_prefix
    end

    def log_type
      'network/base'
    end

    def to_hash
      Vnet::Openflow::Network.new(id: @id,
                                  uuid: @uuid,
                                  type: self.network_type,

                                  ipv4_network: @ipv4_network,
                                  ipv4_prefix: @ipv4_prefix)
    end

    def uninstall
      @dp_info.del_cookie(@cookie)
    end

  end

end
