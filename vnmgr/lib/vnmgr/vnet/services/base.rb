# -*- coding: utf-8 -*-

module Vnmgr::VNet::Services

  class Base < Vnmgr::VNet::Openflow::PacketHandler

    def initialize(params)
      super(params[:datapath])
    end

    def install
    end

    def packet_in(port, message)
    end

  end

end
