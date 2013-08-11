# -*- coding: utf-8 -*-

module Vnet::Openflow::Networks

  class Base
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_reader :datapath
    attr_reader :network_id
    attr_reader :uuid
    attr_reader :datapath_of_bridge

    attr_reader :ports

    attr_reader :cookie
    attr_reader :ipv4_network
    attr_reader :ipv4_prefix

    def initialize(dp, network_map)
      @datapath = dp
      @uuid = network_map.uuid
      @network_id = network_map.network_id
      @datapath_of_bridge = nil

      @ports = {}

      @cookie = @network_id | (COOKIE_PREFIX_NETWORK << COOKIE_PREFIX_SHIFT)
      @ipv4_network = IPAddr.new(network_map.ipv4_network, Socket::AF_INET)
      @ipv4_prefix = network_map.ipv4_prefix
    end

    def broadcast_mac_address
      @datapath_of_bridge && @datapath_of_bridge[:broadcast_mac_address]
    end

    def to_hash
      { :id => @network_id,
        :uuid => @uuid,
        :type => self.network_type,

        :ipv4_network => @ipv4_network,
        :ipv4_prefix => @ipv4_prefix,
      }
    end

    def uninstall
      @datapath.del_cookie(@cookie)
    end


    def add_port(params)
      if @ports[params[:port_number]]
        raise("Port already added to a network.")
      end

      port = {
        # List of ip/mac addresses on this network, etc.
        :mode => params[:port_mode],
      }

      @ports[params[:port_number]] = port

      update_flows
    end

    def del_port_number(port_number)
      port = @ports.delete(port_number)

      if port.nil?
        raise("Port was not added to this network.")
      end

      update_flows
    end

    def set_datapath_of_bridge(datapath_map, dpn_map, should_update)
      # info "network(#{@uuid}): set_datapath_of_bridge: dpn_map:#{dpn_map.inspect}"

      @datapath_of_bridge = {
        :uuid => datapath_map.uuid,
        :display_name => datapath_map.display_name,
        :ipv4_address => datapath_map.ipv4_address,
        :datapath_id => datapath_map.id,
      }

      if dpn_map
        @datapath_of_bridge[:broadcast_mac_address] = Trema::Mac.new(dpn_map.broadcast_mac_address)
      else
        error "network(#{@uuid}): no datapath associated with network."
      end
    end

  end

end
