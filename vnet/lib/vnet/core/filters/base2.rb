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

    def cookie
      @id | COOKIE_TYPE_FILTER2
    end

    def to_hash
      Vnet::Core::Filter.new(id: @id,
                             uuid: @uuid,
                             mode: @mode)
    end

    def install
      return if @interface_id.nil?
      flows = []

      flows_for_ingress_filtering(flows)
      flows_for_egress_filtering(flows)

      @dp_info.add_flows(flows)
    end

    def uninstall
      @dp_info.del_cookie(cookie)
    end

    def added_static(static_id, ipv4_address, port_number, protocol)
      raise NotImplementedError
    end

    def removed_static(static_id)
      raise NotImplementedError
    end

    def update(params)
      ingress_passthrough = params[:ingress_passthrough]
      egress_passthrough = params[:egress_passthrough]

      flows = []

      unless ingress_passthrough == @ingress_passthrough
        @ingress_passthrough = ingress_passthrough
        flows_for_ingress_filtering(flows)
      end

      unless egress_passthrough == @egress_passthrough
       @egress_passthrough = egress_passthrough
        flows_for_egress_filtering(flows)
      end

      @dp_info.add_flows(flows)
    end

    def flows_for_ingress_filtering(flows = [])
      flow = {
        table: TABLE_INTERFACE_INGRESS_FILTER,
        priority: 10,
        match_interface: @interface_id
      }
      flow[:goto_table] = TABLE_OUT_PORT_INTERFACE_INGRESS if @ingress_passthrough

      flows << flow_create(flow)
    end

    def flows_for_egress_filtering(flows = [])
      flow = {
        table: TABLE_INTERFACE_EGRESS_FILTER,
        priority: 10,
        match_interface: @interface_id
      }
      flow[:goto_table] = TABLE_INTERFACE_EGRESS_VALIDATE if @egress_passthrough

      flows << flow_create(flow)
    end

  end

end
