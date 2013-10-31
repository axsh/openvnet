# -*- coding: utf-8 -*-

module Vnet::Openflow::Services

  class Base
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers
    include Vnet::Openflow::PacketHelpers

    def initialize(params)
      @dp_info = params[:dp_info]
      @manager = params[:manager]

      @id = params[:id]
      @uuid = params[:uuid]
      @interface_id = params[:interface_id]
    end

    def cookie(tag = nil)
      value = @id | COOKIE_TYPE_SERVICE
      tag.nil? ? value : (value | (tag << COOKIE_TAG_SHIFT))
    end

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} service/base: #{message}" + (values ? " (#{values})" : '')
    end

    def install
    end

    def packet_in(message)
    end

    def to_hash
      Vnet::Openflow::Service.new(id: @id,
                                  uuid: @uuid,
                                  interface_id: @interface_id)
    end

    def find_ipv4_and_network(message, ipv4_address)
      ipv4_address = ipv4_address != IPV4_BROADCAST ? ipv4_address : nil

      mac_info, ipv4_info = @dp_info.interface_manager.get_ipv4_address(id: @interface_id,
                                                                        any_md: message.match.metadata,
                                                                        ipv4_address: ipv4_address)
      return nil if ipv4_info.nil?

      [mac_info, ipv4_info, @dp_info.network_manager.item(id: ipv4_info[:network_id])]
    end

  end

end
