# -*- coding: utf-8 -*-

module Vnet::Openflow::Services

  class Base < Vnet::Openflow::PacketHandler

    def initialize(params)
      super(params[:datapath])
    end

    def install
    end

    def packet_in(message)
    end

    def to_hash
      {}
    end

  end

end
