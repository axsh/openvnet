# -*- coding: utf-8 -*-

module Vnet::Openflow::Ports

  module Virtual
    include Vnet::Openflow::FlowHelpers

    def port_type
      :virtual
    end

    def install
    end

  end

end
