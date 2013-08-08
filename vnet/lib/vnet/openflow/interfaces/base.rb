# -*- coding: utf-8 -*-

module Vnet::Openflow::Interfaces

  class Base
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_accessor :id
    attr_accessor :uuid
    attr_accessor :owner_datapath_ids

    def initialize(params)
      @datapath = params[:datapath]

      map = params[:map]

      @id = map.id
      @uuid = map.uuid
      @mode = map.mode.to_sym

      @active_datapath_ids = map.active_datapath_id ? [map.active_datapath_id] : nil
      @owner_datapath_ids = map.owner_datapath_id ? [map.owner_datapath_id] : nil
    end
    
    # Update variables by first duplicating to avoid memory
    # consistency issues with values passed to other actors.
    def to_hash
      { :id => @id,
        :uuid => @uuid,
        :mode => @mode,
        :active_datapath_ids => @active_datapath_ids,
        :owner_datapath_ids => @owner_datapath_ids,
      }
    end

  end

end
