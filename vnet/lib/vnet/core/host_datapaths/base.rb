# -*- coding: utf-8 -*-

module Vnet::Core::HostDatapaths

  class Base < Vnet::ItemDpUuid
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_reader :display_name
    attr_reader :dpid
    attr_reader :node_id

    def initialize(params)
      super

      map = params[:map]

      @display_name = map.display_name
      @dpid = map.dpid
      @node_id = map.node_id
    end

    def log_type
      'host_datapath/base'
    end

    def to_hash
      Vnet::Core::HostDatapath.new(id: @id,
                                   uuid: @uuid,
                                   display_name: @display_name,
                                   node_id: @node_id)
    end

  end
end
