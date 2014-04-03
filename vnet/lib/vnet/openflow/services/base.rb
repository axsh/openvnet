# -*- coding: utf-8 -*-

module Vnet::Openflow::Services

  class Base < Vnet::ItemBase
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers
    include Vnet::Openflow::PacketHelpers

    # TODO Integrate constants and methods related to cookie with Interfaces::Base

    OPTIONAL_TYPE_MASK      = 0xf

    OPTIONAL_TYPE_TAG      = 0x1
    OPTIONAL_TYPE_NETWORK  = 0x2

    OPTIONAL_VALUE_SHIFT    = 36
    OPTIONAL_VALUE_MASK    = 0xfffff

    attr_accessor :uuid
    attr_accessor :interface_id
    attr_accessor :type
    attr_reader :networks

    def initialize(params)
      super

      @id = params[:id]
      @uuid = params[:uuid]
      @type = params[:type]
      @interface_id = params[:interface_id]
      @networks = {}
    end

    def cookie(type = 0, value = 0)
      unless type & 0xf == type
        raise "Invalid cookie optional type: %#x" % type
      end
      unless value & OPTIONAL_VALUE_MASK == value
        raise "Invalid cookie optional value: %#x" % value
      end
      @id |
        COOKIE_TYPE_SERVICE |
        type << COOKIE_TAG_SHIFT |
        value << OPTIONAL_VALUE_SHIFT
    end

    def del_cookie(type = 0, value = 0)
      cookie_value = cookie(type, value)
      cookie_mask = COOKIE_PREFIX_MASK | COOKIE_ID_MASK
      unless type == 0 && value == 0
        cookie_mask |= COOKIE_TAG_MASK
      end

      @dp_info.del_cookie(cookie_value, cookie_mask)
    end

    def cookie_for_network(value)
      cookie(OPTIONAL_TYPE_NETWORK, value)
    end

    def del_cookie_for_network(value)
      del_cookie(OPTIONAL_TYPE_NETWORK, value)
    end

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} service/base: #{message}" + (values ? " (#{values})" : '')
    end

    def install
    end

    def uninstall
      del_cookie
    end

    def packet_in(message)
    end

    def to_hash
      Vnet::Openflow::Service.new(id: @id,
                                  uuid: @uuid,
                                  type: @type,
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

    def add_network_unless_exists(network_id, cookie_id)
      return if @networks[network_id]
      @networks[network_id] = { network_id: network_id,
                                cookie_id: cookie_id }

      add_network(network_id, cookie_id)
    end

    def add_network(network_id, cookie_id)
      debug log_format("add_network")
      # Implement in subclass if needed
    end

    def remove_network_if_exists(network_id)
      return unless @networks.member?(network_id)
      network = @networks.delete(network_id)
      remove_network(network[:network_id])
      del_cookie_for_network(network[:cookie_id])
    end

    def remove_network(network_id)
    end

    def remove_all_networks
      removed_networks, @networks = @networks, nil
      removed_networks.values.each do |network|
        remove_network(network[:network_id])
        del_cookie_for_network(network[:cookie_id])
      end
    end

    protected

    def find_client_infos(port_number, server_mac_info, server_ipv4_info)
      interface = @dp_info.interface_manager.item(port_number: port_number)
      return [] if interface.nil?

      client_infos = interface.get_ipv4_infos(network_id: server_ipv4_info && server_ipv4_info[:network_id])

      # info log_format("find_client_info", "#{interface.inspect}")
      # info log_format("find_client_info", "server_mac_info:#{server_mac_info.inspect}")
      # info log_format("find_client_info", "server_ipv4_info:#{server_ipv4_info.inspect}")
      # info log_format("find_client_info", "client_infos:#{client_infos.inspect}")

      client_infos
    end

  end

end
