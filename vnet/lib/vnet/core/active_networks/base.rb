# -*- coding: utf-8 -*-

module Vnet::Core::ActiveNetworks

  class Base < Vnet::ItemDpBase
    include Vnet::Openflow::FlowHelpers

    attr_reader :network_id
    attr_reader :datapath_id

    def initialize(params)
      super

      map = params[:map]

      @network_id = map.network_id
      @datapath_id = map.datapath_id
    end

    def mode
      :base
    end

    def log_type
      'active_network/base'
    end

    def pretty_id
      "#{mode}/#{id}"
    end

    def pretty_properties
      "network_id:#{@network_id} datapath_id:#{@datapath_id}"
    end

    def cookie
      @id | COOKIE_TYPE_ACTIVE_NETWORK
    end

    def to_hash
      Vnet::Core::ActiveNetwork.new(id: @id,
                                    mode: self.mode,

                                    network_id: @network_id,
                                    datapath_id: @datapath_id)
    end

  end

end
