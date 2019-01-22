# -*- coding: utf-8 -*-

module Vnet::Core::HostDatapaths

  class Base < Vnet::ItemDpUuid
    include Celluloid::Logger

    attr_reader :display_name
    attr_reader :dpid
    attr_reader :node_id
    attr_reader :enable_ovs_learn_action

    def initialize(params)
      super

      params[:map].tap { |map|
        @display_name = map.display_name
        @dpid = map.dpid
        @node_id = map.node_id
        @enable_ovs_learn_action = map.enable_ovs_learn_action
      }
    end

    def log_type
      'host_datapath/base'
    end

    def to_hash
      Vnet::Core::HostDatapath.new(id: @id,
                                   uuid: @uuid,
                                   display_name: @display_name,
                                   node_id: @node_id,
                                   enable_ovs_learn_action: @enable_ovs_learn_action)
    end

  end
end
