# -*- coding: utf-8 -*-

module Vnet::Core::Filters

  class Base2 < Vnet::ItemDpUuidMode
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

#    attr_accessor :dp_info
    attr_reader :interface_id

    def initialize(params)
      super
     
      map = params[:map]

      @interface_id = map.interface_id
      @egress_passthrough = map.egress_passthrough
      @ingress_passthrough = map.ingress_passthrough

    end

    def pretty_properties
      "interface_id:#{@interface_id}" 
    end

    # We make a class method out of cookie so we can access
    # it easily in unit tests.
    def self.cookie
      raise NotImplementedError
    end

    def cookie
      @id | COOKIE_TYPE_FILTER
    end

    def to_hash
      Vnet::Core::Filter.new(id: @id,
                             uuid: @uuid,
                             mode: @mode)
    end

    def install
      raise NotImplementedError
    end

    def uninstall
      @dp_info.del_cookie(cookie)
    end

    def added_static(static_id, ipv4_address, port_number, protocol)
    end

    def removed_static(static_id)
    end

  end

end
