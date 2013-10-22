# -*- coding: utf-8 -*-

module Vnet::Openflow::Interfaces

  class Base
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers
    include Vnet::Openflow::PacketHelpers

    OPTIONAL_TYPE_MASK      = 0xf

    OPTIONAL_TYPE_TAG      = 0x1
    OPTIONAL_TYPE_IP_LEASE  = 0x2
    OPTIONAL_TYPE_MAC_LEASE = 0x3
    OPTIONAL_TYPE_IP_RANGE  = 0x4

    OPTIONAL_VALUE_SHIFT    = 36
    OPTIONAL_VALUE_MASK    = 0xfffff

    TAG_ARP_REQUEST_INTERFACE = 0x1
    TAG_ARP_REQUEST_FLOOD     = 0x2
    TAG_ARP_LOOKUP            = 0x4
    TAG_ARP_REPLY             = 0x5
    TAG_ICMP_REQUEST          = 0x6

    attr_accessor :id
    attr_accessor :uuid
    attr_accessor :mode
    attr_accessor :active_datapath_ids
    attr_accessor :owner_datapath_ids
    attr_accessor :display_name

    attr_reader :port_number

    def initialize(params)
      @dp_info = params[:dp_info]
      @manager = params[:manager]

      map = params[:map]

      @id = map.id
      @uuid = map.uuid
      @mode = map.mode.to_sym

      @display_name = map.display_name

      @mac_addresses = {}

      # The 'owner_datapath_ids' set has two possible states; the set
      # can contain zero or more datapaths that can activate this
      # interface, or if nil it can either be activated by any
      # datapath or should be active on all relevant datapaths.
      #
      # The 'active_datapath_ids' set has several possible states,
      # some depending on the interface type; the set can contain zero
      # or more datapaths on which the interface is active, or if nil
      # it is interface dependent.
      #
      # Note, currently we're using a single value in the db and as
      # such the implementation below is subject to change.

      if map.owner_datapath_id
        @owner_datapath_ids = [map.owner_datapath_id]
        @active_datapath_ids = map.active_datapath_id ? [map.active_datapath_id] : []
      else
        @owner_datapath_ids = nil
        @active_datapath_ids = map.active_datapath_id ? [map.active_datapath_id] : nil
      end
    end

    def cookie(type = 0, value = 0)
      unless type & 0xf == type
        raise "Invalid cookie optional type: %#x" % type
      end
      unless value & OPTIONAL_VALUE_MASK == value
        raise "Invalid cookie optional value: %#x" % value
      end
      @id |
        (COOKIE_PREFIX_INTERFACE << COOKIE_PREFIX_SHIFT) |
        type << COOKIE_TAG_SHIFT |
        value << OPTIONAL_VALUE_SHIFT
    end

    def cookie_for_tag(value)
      cookie(OPTIONAL_TYPE_TAG, value)
    end

    def cookie_for_ip_lease(value)
      cookie(OPTIONAL_TYPE_IP_LEASE, value)
    end

    def del_cookie(type = 0, value = 0)
      cookie_value = cookie(type, value)
      cookie_mask = COOKIE_PREFIX_MASK | COOKIE_ID_MASK | COOKIE_TAG_MASK

      @dp_info.network_manager.async.update_interface(event: :remove_all,
                                                      interface_id: @id)
      @dp_info.del_cookie(cookie_value, cookie_mask)
    end

    def del_cookie_for_ip_lease(value)
      del_cookie(OPTIONAL_TYPE_IP_LEASE, value)
    end

    # Update variables by first duplicating to avoid memory
    # consistency issues with values passed to other actors.
    def to_hash
      Vnet::Openflow::Interface.new(id: @id,
                                    uuid: @uuid,
                                    mode: @mode,
                                    port_number: @port_number,
                                    display_name: @display_name,
                                    mac_addresses: @mac_addresses,

                                    active_datapath_ids: @active_datapath_ids,
                                    owner_datapath_ids: @owner_datapath_ids)
    end

    def install
    end

    def uninstall
      debug "interfaces: removing flows..."
      del_cookie
    end

    def update_port_number(new_number)
      return if @port_number == new_number

      @port_number = new_number

      @dp_info.network_manager.async.update_interface(event: :update_all,
                                                      interface_id: @id,
                                                      port_number: @port_number)
    end

    #
    # Manage MAC and IP addresses:
    #

    def add_mac_address(params)
      #debug log_format("add_ipv4_address", params.inspect)
      return if @mac_addresses[params[:mac_lease_id]]

      mac_addresses = @mac_addresses.dup
      mac_addresses[params[:mac_lease_id]] = {
        :ipv4_addresses => [],
        :mac_address => params[:mac_address],
      }

      @mac_addresses = mac_addresses

      # Add to port...
      nil
    end

    def remove_mac_address(params)
      debug log_format("remove_mac_address", params.inspect)

      mac_info = @mac_addresses[params[:mac_lease_id]]
      return unless mac_info

      mac_info[:ipv4_addresses].each do |ipv4_info|
        remove_ipv4_address(ip_lease_id: ipv4_info[:ip_lease_id])
      end

      mac_addresses = @mac_addresses.dup
      mac_addresses.delete(params[:mac_lease_id])
      @mac_addresses = mac_addresses
    end

    def add_ipv4_address(params)
      #debug log_format("add_ipv4_address", params.inspect)

      mac_info = @mac_addresses[params[:mac_lease_id]]
      return unless mac_info

      # Check if the address already exists.

      ipv4_info = {
        :network_id => params[:network_id],
        :network_type => params[:network_type],
        :ipv4_address => params[:ipv4_address],
        :ip_lease_id => params[:ip_lease_id],
        :cookie_id => params[:cookie_id],
      }

      ipv4_addresses = mac_info[:ipv4_addresses].dup
      ipv4_addresses << ipv4_info

      mac_info[:ipv4_addresses] = ipv4_addresses

      [mac_info, ipv4_info]
    end

    def remove_ipv4_address(params)
      debug log_format("remove_ipv4_address", params.inspect)

      ipv4_info = nil
      ipv4_addresses = nil
      mac_info = @mac_addresses.values.find do |m|
        ipv4_info, ipv4_addresses = m[:ipv4_addresses].partition do |i|
          i[:ip_lease_id] == params[:ip_lease_id]
        end
        ipv4_info = ipv4_info.first
      end
      return unless mac_info

      mac_info[:ipv4_addresses] = ipv4_addresses

      [mac_info, ipv4_info]
    end

    # TODO refactoring
    def get_ipv4_address(params)
      case
      when params[:any_md]
        network_id = md_to_id(:network, params[:any_md])
        interface_id = md_to_id(:interface, params[:any_md])
        return nil if network_id.nil? && interface_id.nil?
      when params[:network_md]
        network_id = md_to_id(:network, params[:network_md])
        return nil if network_id.nil?
      else
        network_id = nil
      end

      ipv4_info = nil
      ipv4_address = params[:ipv4_address]

      mac_info = @mac_addresses.values.detect { |mac_info|
        ipv4_info = mac_info[:ipv4_addresses].detect { |ipv4_info|
          next false if network_id && ipv4_info[:network_id] != network_id
          next true if ipv4_address.nil?

          ipv4_info[:ipv4_address] == ipv4_address
        }
      }

      mac_info && [mac_info, ipv4_info]
    end

    def find_ipv4_and_network(message, ipv4_address)
      ipv4_address = ipv4_address != IPV4_BROADCAST ? ipv4_address : nil

      mac_info, ipv4_info = get_ipv4_address(id: @interface_id,
                                             any_md: message.match.metadata,
                                             ipv4_address: ipv4_address)
      return nil if ipv4_info.nil?

      [mac_info, ipv4_info, @dp_info.network_manager.item(id: ipv4_info[:network_id])]
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} interfaces/base: #{message}" + (values ? " (#{values})" : '')
    end

  end

end
