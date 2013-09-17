# -*- coding: utf-8 -*-

module Vnet::Openflow::Ports

  module Physical
    include Vnet::Openflow::FlowHelpers

    def port_type
      :physical
    end

    def install
    end

  end

end
