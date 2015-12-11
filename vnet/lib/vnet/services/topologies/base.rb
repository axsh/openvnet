# -*- coding: utf-8 -*-

module Vnet::Services::Topologies

  class Base < Vnet::ItemVnetUuid
    include Celluloid::Logger

    def initialize(params)
      super

      map = params[:map]
    end    
    
    def log_type
      'topology/base'
    end

    def to_hash
      Vnet::Core::Topology.new(id: @id,
                               uuid: @uuid)
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

    def log_format_dp_nw(message, datapath_id, network_id)
      log_format(message, "datapath_id:#{datapath_id} network_id:#{network_id}")
    end

    def log_format_dp_nw_if(message, datapath_id, network_id, interface_id)
      log_format(message, "datapath_id:#{datapath_id} network_id:#{network_id} interface_id:#{interface_id}")
    end

  end

end
