# -*- coding: utf-8 -*-

module Vnet::Openflow::Routers

  class Base
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_reader :id
    attr_reader :uuid
    attr_reader :mac_address

    def initialize(params)
      @dp_info = params[:dp_info]

      map = params[:map]

      @id = map.id
      @uuid = map.uuid

      @mac_address = Trema::Mac.new(map.mac_address)
    end

    def cookie
      @id | COOKIE_TYPE_ROUTE_LINK
    end

    def to_hash
      Vnet::Openflow::Router.new(id: @id,
                                 uuid: @uuid,
                                 #mode: @mode,

                                 mac_address: @mac_address)
    end

    #
    # Events: 
    #

    def install
    end    

    def uninstall
    end    

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} routers/base: #{message} (route_link:#{@uuid}/#{@id}#{values ? ' ' : ''}#{values})"
    end

  end

end
