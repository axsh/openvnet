# -*- coding: utf-8 -*-

module Vnet::Openflow::Interfaces

  class Base
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_accessor :id
    attr_accessor :uuid
    attr_accessor :active_datapath_ids
    attr_accessor :owner_datapath_ids

    def initialize(params)
      @datapath = params[:datapath]

      map = params[:map]

      @id = map.id
      @uuid = map.uuid
      @mode = map.mode.to_sym

      @mac_addresses = {}

      @active_datapath_ids = map.active_datapath_id ? [map.active_datapath_id] : nil
      @owner_datapath_ids = map.owner_datapath_id ? [map.owner_datapath_id] : nil
    end
    
    # Update variables by first duplicating to avoid memory
    # consistency issues with values passed to other actors.
    def to_hash
      { :id => @id,
        :uuid => @uuid,
        :mode => @mode,
        :mac_addresses => @mac_addresses,

        :active_datapath_ids => @active_datapath_ids,
        :owner_datapath_ids => @owner_datapath_ids,
      }
    end

    def add_mac_address(mac_address)
      return nil if @mac_addresses.has_key? mac_address

      mac_addresses = @mac_addresses.dup
      mac_addresses[mac_address] = {
        :ipv4_addresses => [],
      }

      @mac_addresses = mac_addresses

      # Add to port...
      nil
    end

    def add_ipv4_address(params)
      info = @mac_addresses[params[:mac_address]]

      return nil if info.nil?

      # Check if the address already exists.

      ipv4_addresses = info[:ipv4_addresses].dup
      ipv4_addresses << {
        :network_id => params[:network_id],
        :network_type => params[:network_type],
        :ipv4_address => params[:ipv4_address],
      }

      info[:ipv4_addresses] = ipv4_addresses

      nil
    end

  end

end
