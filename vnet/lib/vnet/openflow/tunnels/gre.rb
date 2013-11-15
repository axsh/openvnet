# -*- coding: utf-8 -*-

module Vnet::Openflow::Tunnels

  class Gre < Base
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_reader :mask

    def initialize(params)
      super(params)
      @mask = GRE_FLAG_MASK
    end
  end
end
