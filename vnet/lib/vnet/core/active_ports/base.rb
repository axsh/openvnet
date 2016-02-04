# -*- coding: utf-8 -*-

module Vnet::Core::ActivePorts

  class Base < Vnet::ItemDpBase
    include Vnet::Openflow::FlowHelpers

    attr_reader :port_id
    attr_reader :datapath_id

    attr_reader :port_name
    attr_reader :port_number

    def initialize(params)
      super

      map = params[:map]

      @datapath_id = map.datapath_id

      @port_name = map.port_name
      @port_number = map.port_number
    end

    def mode
      :base
    end

    def log_type
      'active_port/base'
    end

    def pretty_id
      "#{mode}/#{id}"
    end

    def pretty_properties
      "datapath_id:#{@datapath_id} port_name:#{@port_name} port_number:#{@port_number}"
    end

    def to_hash
      Vnet::Core::ActivePort.new(id: @id,
                                 datapath_id: @datapath_id,

                                 port_name: @port_name,
                                 port_number: @port_number)
    end

    class << self

      def cookie_for_id(item_id)
        item_id | Vnet::Constants::OpenflowFlows::COOKIE_TYPE_ACTIVE_PORT
      end

      def add_flows_for_id(dp_info, item_id)
      end

    end
  end

end
