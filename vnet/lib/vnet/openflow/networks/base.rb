# -*- coding: utf-8 -*-

module Vnet::Openflow::Networks

  class Base
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    Flow = Vnet::Openflow::Flow

    attr_reader :id
    attr_reader :uuid
    attr_reader :datapath_of_bridge

    attr_reader :interfaces

    attr_reader :cookie
    attr_reader :ipv4_network
    attr_reader :ipv4_prefix

    def initialize(dp_info, network_map)
      @dp_info = dp_info

      @id = network_map.id
      @uuid = network_map.uuid

      @datapath_of_bridge = nil

      @interfaces = {}

      @cookie = @id | COOKIE_TYPE_NETWORK
      @ipv4_network = IPAddr.new(network_map.ipv4_network, Socket::AF_INET)
      @ipv4_prefix = network_map.ipv4_prefix
    end

    def to_hash
      { :id => @id,
        :uuid => @uuid,
        :type => self.network_type,

        :ipv4_network => @ipv4_network,
        :ipv4_prefix => @ipv4_prefix,
      }
    end

    def uninstall
      @dp_info.del_cookie(@cookie)
    end

    #
    # Interfaces:
    #

    # The 'interfaces' hash holds all interfaces on this network that
    # are of interest to network manager. These include 'vif' and
    # those 'simulated' interfaces that provide services for other
    # datapaths.

    def insert_interface(params)
      if @interfaces[params[:interface_id]]
        raise("Interface already added to a network.")
      end

      @interfaces[params[:interface_id]] = {
        :mode => params[:mode],
        :port_number => params[:port_number],
      }

      update_flows if params[:port_number]

      self
    end

    def remove_interface(params)
      interface = @interfaces.delete(params[:interface_id])
      return if interface.nil?

      update_flows if interface[:port_number] && !params[:no_update]

      self
    end

    def update_interface(params)
      interface = @interfaces[params[:interface_id]]
      return if interface.nil?

      if params.has_key? :port_number
        interface[:port_number] = params[:port_number]
        update_flows unless params[:no_update]
      end

      self
    end

    def set_datapath_of_bridge(datapath_info)
      # info "network(#{@uuid}): set_datapath_of_bridge: dpn_map:#{dpn_map.inspect}"

      @datapath_of_bridge = {
        :uuid => datapath_info.uuid,
        :display_name => datapath_info.display_name,
        :ipv4_address => datapath_info.ipv4_address,
        :datapath_id => datapath_info.id,
      }
    end

  end

end
