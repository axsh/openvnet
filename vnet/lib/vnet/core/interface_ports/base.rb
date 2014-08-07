# -*- coding: utf-8 -*-

module Vnet::Core::InterfacePorts

  class Base < Vnet::ItemDpBase
    include Vnet::Openflow::FlowHelpers

    attr_reader :interface_id
    attr_reader :interface_mode
    attr_reader :datapath_id

    attr_accessor :singular
    attr_accessor :port_name
    attr_accessor :port_number

    def initialize(params)
      super

      @datapath_info = params[:datapath_info]

      map = params[:map]

      @interface_id = map.interface_id
      @interface_mode = map.interface_mode.to_sym
      @datapath_id = map.datapath_id

      @port_name = map.port_name
      @singular = map.singular
    end

    def mode
      :base
    end

    def log_type
      'interface_port/base'
    end

    def pretty_id
      "#{mode}/#{id}"
    end

    def pretty_properties
      "interface_id:#{@interface_id} interface_mode:#{@interface_mode}" +
        (@datapath_id ? " datapath_id:#{@datapath_id}" : '') +
        (@port_name ? ' port_name:' + @port_name : '') +
        (@singular ? ' singular' : '')
    end

    def allowed_datapath?
      return false if @datapath_info.nil?

      if @datapath_id
        return @datapath_id == @datapath_info.id
      else
        return true
      end
    end

    def to_hash
      Vnet::Core::InterfacePort.new(id: @id,
                                    mode: self.mode,

                                    interface_id: @interface_id,
                                    interface_mode: @interface_mode,
                                    datapath_id: @datapath_id,

                                    port_name: @port_name,
                                    singular: @singular)
    end

  end

end
