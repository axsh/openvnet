module Vnet::Openflow::VnetEdge
  class TranslationHandler < Vnet::Openflow::PacketHandler
    include Celluloid::Logger

    def initialize(params)
      @datapath = params[:datapath]
    end

    def packet_in(message)
      debug log_format('packet_in', message.cookie)
    end

    def install
      debug log_format('install')
    end

    private
    
    def log_format(message, values = nil)
      "#{@dpid_s} translation_handler: #{message}" + (values ? " (#{values})" : '')
    end
  end
end
