module Vnet::Openflow::VnetEdge
  class TranslationHandler < Vnet::Openflow::PacketHandler
    def initialize
    end

    def packet_in(message)
      true
    end
  end
end
