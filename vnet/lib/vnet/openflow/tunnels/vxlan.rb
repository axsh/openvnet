# -*- coding: utf-8 -*-

module Vnet::Openflow::Tunnels

  class Vxlan < Base
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_reader :mask

    def initialize(params)
      super(params)
      @mask = VXLAN_FLAG_MASK
    end
  end
end
