# -*- coding: utf-8 -*-

module Vnet::Services::Topologies

  class Base < Vnet::ItemDpUuid
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

  end

end
