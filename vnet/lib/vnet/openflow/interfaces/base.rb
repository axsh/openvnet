# -*- coding: utf-8 -*-

module Vnet::Openflow::Interfaces

  class Base
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers
    include Vnet::Openflow::PacketHelpers

    attr_accessor :id
    attr_accessor :uuid
    attr_accessor :mode
    attr_accessor :active_datapath_ids
    attr_accessor :owner_datapath_ids

    attr_reader :port_number

    def initialize(params)
      @datapath = params[:datapath]
      @manager = params[:manager]

      @dpid = @datapath.dpid
      @dpid_s = "0x%016x" % @datapath.dpid

      map = params[:map]

      @id = map.id
      @uuid = map.uuid
      @mode = map.mode.to_sym

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
    
    def cookie(tag = nil)
      value = @id | (COOKIE_PREFIX_INTERFACE << COOKIE_PREFIX_SHIFT)
      tag.nil? ? value : (value | (tag << COOKIE_TAG_SHIFT))
    end

    # Update variables by first duplicating to avoid memory
    # consistency issues with values passed to other actors.
    def to_hash
      Vnet::Openflow::Interface.new(id: @id,
                                    uuid: @uuid,
                                    mode: @mode,
                                    port_number: @port_number,
                                    mac_addresses: @mac_addresses,

                                    active_datapath_ids: @active_datapath_ids,
                                    owner_datapath_ids: @owner_datapath_ids)
    end

    def install
    end

    def uninstall
      debug "interfaces: removing flows..."

      cookie_value = @id | (COOKIE_PREFIX_INTERFACE << COOKIE_PREFIX_SHIFT)
      cookie_mask = COOKIE_PREFIX_MASK | COOKIE_ID_MASK

      @datapath.del_cookie(cookie_value, cookie_mask)
    end

    def add_mac_address(mac_address)
      return nil if @mac_addresses.has_key? mac_address

      mac_addresses = @mac_addresses.dup
      mac_addresses[mac_address] = {
        :ipv4_addresses => [],
        :mac_address => mac_address,
      }

      @mac_addresses = mac_addresses

      # Add to port...
      nil
    end

    def add_ipv4_address(params)
      mac_info = @mac_addresses[params[:mac_address]]

      return nil if mac_info.nil?

      # Check if the address already exists.

      ipv4_info = {
        :network_id => params[:network_id],
        :network_type => params[:network_type],
        :ipv4_address => params[:ipv4_address],
      }

      ipv4_addresses = mac_info[:ipv4_addresses].dup
      ipv4_addresses << ipv4_info

      mac_info[:ipv4_addresses] = ipv4_addresses

      [mac_info, ipv4_info]
    end

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

      mac_info = @mac_addresses.detect { |mac_address, mac_info|
        ipv4_info = mac_info[:ipv4_addresses].detect { |ipv4_info|
          next false if network_id && ipv4_info[:network_id] != network_id
          next true if ipv4_address.nil?

          ipv4_info[:ipv4_address] == ipv4_address
        }
      }

      mac_info && [mac_info[1], ipv4_info]
    end

    def find_ipv4_and_network(message, ipv4_address)
      ipv4_address = ipv4_address != IPV4_BROADCAST ? ipv4_address : nil

      mac_info, ipv4_info = get_ipv4_address(id: @interface_id,
                                             any_md: message.match.metadata,
                                             ipv4_address: ipv4_address)
      return nil if ipv4_info.nil?

      [mac_info, ipv4_info, @datapath.network_manager.item(id: ipv4_info[:network_id])]
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dpid_s} interfaces/base: #{message}" + (values ? " (#{values})" : '')
    end

  end

end
