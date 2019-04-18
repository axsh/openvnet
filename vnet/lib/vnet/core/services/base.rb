# -*- coding: utf-8 -*-

module Vnet::Core::Services

  class Base < Vnet::ItemDpUuidMode
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers
    include Vnet::Openflow::PacketHelpers

    # TODO Integrate constants and methods related to cookie with Interfaces::Base

    OPTIONAL_TYPE_MASK     = 0xf

    OPTIONAL_TYPE_TAG      = 0x1
    OPTIONAL_TYPE_NETWORK  = 0x2

    OPTIONAL_VALUE_SHIFT   = 36
    OPTIONAL_VALUE_MASK    = 0xfffff

    attr_accessor :interface_id
    attr_reader :networks

    def initialize(params)
      super

      map = params[:map]
      @interface_id = map.interface_id

      @networks = {}
    end

    def log_type
      'service/base'
    end

    def pretty_properties
      "mode:#{@mode}"
    end

    def cookie(type = 0, value = 0)
      unless (type & 0xf) == type
        raise "Invalid cookie optional type: %#x" % type
      end
      unless (value & OPTIONAL_VALUE_MASK) == value
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

    def uninstall
      del_cookie
    end

    def packet_in(message)
    end

    def to_hash
      Vnet::Core::Service.new(id: @id,
                              uuid: @uuid,
                              mode: @mode,
                              interface_id: @interface_id)
    end

    #
    # Manage MAC and IP addresses:
    #

    def get_mac_ipv4(ipv4_address, network_id = nil)
      mac_info = nil
      ipv4_info = nil
      ipv4_address = (ipv4_address != IPV4_ZERO && ipv4_address != IPV4_BROADCAST) ? ipv4_address : nil

      @dp_info.interface_manager.get_interface_addrs(id: @interface_id).tap { |if_addrs|
        if if_addrs.nil?
          debug log_format_h('get_interface_addrs failed', interface_id: @interface_id)
          return
        end
      
        debug log_format_h('get_interface_addrs from interface', interface_id: @interface_id, if_addrs: if_addrs)

        mac_info = if_addrs.values.detect { |mac_info|
          ipv4_info = mac_info[:ipv4_addresses].detect { |ipv4_info|
            next if network_id && network_id != ipv4_info[:network_id]
            next if ipv4_address && ipv4_address != ipv4_info[:ipv4_address]
            true
          }
        }
      }

      return nil if mac_info.nil? || ipv4_info.nil?
      return [mac_info, ipv4_info]
    end

    def get_mac_ipv4_network(ipv4_address)
      get_mac_ipv4(ipv4_address, nil).tap { |mac_info, ipv4_info|
        return nil if mac_info.nil? || ipv4_info.nil?
        return [mac_info, ipv4_info, ipv4_info && @dp_info.network_manager.retrieve(id: ipv4_info[:network_id])]
      }
    end

    def select_mac_ipv4(ipv4_address, network_id, params = { id: @interface_id })
      if_addrs = @dp_info.interface_manager.get_interface_addrs(params)

      if if_addrs.nil?
        debug log_format_h('get_interface_addrs failed', interface_id: @interface_id)
        return []
      end

      [].tap { |list|
        if_addrs.each { |mac_lease_id, mac_info|
          mac_info[:ipv4_addresses].each { |ipv4_info|
            next if network_id && network_id != ipv4_info[:network_id]
            next if ipv4_address && ipv4_address != ipv4_info[:ipv4_address]

            list << [mac_info, ipv4_info]
          }
        }
      }
    end

    #
    # Networks:
    #

    def add_network_unless_exists(network_id, cookie_id, segment_id)
      return if @networks[network_id]
      @networks[network_id] = { network_id: network_id,
                                segment_id: segment_id,
                                cookie_id: cookie_id }

      add_network(network_id, cookie_id, segment_id)
    end

    def add_network(network_id, cookie_id, segment_id)
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
      client_infos = select_mac_ipv4(nil, server_ipv4_info && server_ipv4_info[:network_id], port_number: port_number)

      # info log_format("find_client_info", "server_mac_info:#{server_mac_info.inspect}")
      # info log_format("find_client_info", "server_ipv4_info:#{server_ipv4_info.inspect}")
      # info log_format("find_client_info", "client_infos:#{client_infos.inspect}")

      client_infos
    end

  end

end
