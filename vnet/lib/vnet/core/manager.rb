# -*- coding: utf-8 -*-

module Vnet::Core
  class Manager < Vnet::Manager

    attr_reader :datapath_info

    def initialize(info, options = {})
      @dp_info = info
      @datapath_info = nil
      @log_prefix = "#{@dp_info.try(:dpid_s)} #{self.class.name.to_s.demodulize.underscore}: "

      # Call super last in order to ensure that the celluloid actor is
      # not activated before we have initialized the required
      # variables.
      super
    end

    def handle_dynamic_load(params)
      super.tap do |item|

        # Flush messages should be done after install. (Make sure
        # interfaces are loaded using sync.
        flush_messages(item.id,
                       item.public_method(:mac_address) && item.mac_address) if item
      end
    end

    #
    # Internal methods:
    #

    private

    def flush_messages(item_id, mac_address)
      return if item_id.nil? || item_id <= 0

      messages = @messages.delete(item_id)

      # The item must have a 'mac_address' attribute that will be used
      # as the eth_src address for sending packet out messages.
      if messages.nil? || mac_address.nil?
        debug log_format('flush messages failed', "id:#{item_id} mac_address:#{mac_address}")
        return
      end

      messages.each { |message|
        packet = message[:message]
        packet.match.in_port = OFPP_CONTROLLER
        packet.match.eth_src = mac_address

        @dp_info.send_packet_out(packet, OFPP_TABLE)
      }
    end

  end
end
