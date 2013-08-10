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

    def find_ipv4_and_network(message, ipv4_address)
      ipv4_address = ipv4_address != IPV4_BROADCAST ? ipv4_address : nil

      mac_info, ipv4_info = @datapath.interface_manager.get_ipv4_address(id: @interface_id,
                                                                         any_md: message.match.metadata,
                                                                         ipv4_address: ipv4_address)
      return nil if ipv4_info.nil?

      [mac_info, ipv4_info, @datapath.network_manager.network_by_id(ipv4_info[:network_id])]
    end

  end

end
