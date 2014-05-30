# -*- coding: utf-8 -*-

module Vnet::Core::ActiveInterfaces

  class Base < Vnet::ItemDpBase
    include Vnet::Openflow::FlowHelpers

    attr_reader :interface_id
    attr_reader :datapath_id

    attr_reader :port_name
    attr_reader :label

    def initialize(params)
      super

      map = params[:map]

      @interface_id = map.interface_id
      @datapath_id = map.datapath_id

      @port_name = map.port_name
      @label = map.label
    end

    def log_type
      'active_interface/base'
    end

    def pretty_properties
      "interface_id:#{@interface_id} datapath_id:#{@datapath_id} label:#{@label} port_name:#{@port_name}"
    end

    def cookie
      @id | COOKIE_TYPE_ACTIVE_INTERFACE
    end

    def to_hash
      Vnet::Core::ActiveInterface.new(id: @id,
                                      interface_id: @interface_id,
                                      datapath_id: @datapath_id,

                                      port_name: @port_name,
                                      label: @label)
    end

    #
    # Events: 
    #

    def install
      flows = []

      @dp_info.add_flows(flows)
    end

    def uninstall
      @dp_info.del_cookie(self.cookie)
    end

    #
    # Internal methods:
    #

    private

    def flows_for_base(flows)
    end

  end

end
