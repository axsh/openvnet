# -*- coding: utf-8 -*-

require 'celluloid'

module Vnet::Openflow

  class Switch
    include Celluloid
    include Celluloid::Logger
    include FlowHelpers
    include Vnet::Event::Dispatchable

    def initialize(dp, name = nil)
      @datapath = dp || raise("cannot create a Switch object without a valid datapath")
      @ports = {}

      cookie_manager = @datapath.cookie_manager

      @catch_flow_cookie   = cookie_manager.acquire(:switch)
      @default_flow_cookie = cookie_manager.acquire(:switch)
      @test_flow_cookie    = cookie_manager.acquire(:switch)
    end

    #
    # Switch values:
    #

    def eth_ports
      @ports.values.find_all { |port| port.eth? }
    end

    # Temporary method to get access to ports until we make a proper
    # port manager that handles threading.
    def get_port(port_number)
      @ports[port_number]
    end

    #
    # Event handlers:
    #

    def create_default_flows
      #
      # Add default flows:
      #

      flows = []

      flow_options = {:cookie => @default_flow_cookie}

      flows << Flow.create(TABLE_CLASSIFIER, 1, {:tunnel_id => 0}, nil, flow_options)
      flows << Flow.create(TABLE_CLASSIFIER, 0, {}, {},
                           flow_options.merge(md_create(:remote => nil)).merge!(:goto_table => TABLE_TUNNEL_PORTS))

      flows << Flow.create(TABLE_HOST_PORTS,         0, {}, nil, flow_options)
      flows << Flow.create(TABLE_TUNNEL_PORTS,       0, {}, nil, flow_options)
      flows << Flow.create(TABLE_TUNNEL_NETWORK_IDS, 0, {}, nil, flow_options)

      flows << Flow.create(TABLE_NETWORK_CLASSIFIER, 0, {}, nil, flow_options)

      flows << Flow.create(TABLE_VIRTUAL_SRC,  0, {}, nil, flow_options)
      flows << Flow.create(TABLE_PHYSICAL_SRC, 0, {}, nil, flow_options)
      flows << Flow.create(TABLE_PHYSICAL_SRC, 40, {:eth_type => 0x0800}, nil, flow_options)
      flows << Flow.create(TABLE_PHYSICAL_SRC, 40, {:eth_type => 0x0806}, nil, flow_options)

      flows << Flow.create(TABLE_ROUTER_ENTRY, 0, {}, nil, flow_options)
      flows << Flow.create(TABLE_ROUTER_ENTRY, 10, md_create(:virtual => nil), nil,
                           flow_options.merge(:goto_table => TABLE_VIRTUAL_DST))
      flows << Flow.create(TABLE_ROUTER_ENTRY, 10, md_create(:physical => nil), nil,
                           flow_options.merge(:goto_table => TABLE_PHYSICAL_DST))
      flows << Flow.create(TABLE_ROUTER_SRC,   0, {}, nil, flow_options)
      flows << Flow.create(TABLE_ROUTER_LINK,  0, {}, nil, flow_options)
      flows << Flow.create(TABLE_ROUTER_DST,   0, {}, nil, flow_options)

      flows << Flow.create(TABLE_ARP_LOOKUP,   0, {}, nil, flow_options)

      flows << Flow.create(TABLE_VIRTUAL_DST,  0, {}, nil, flow_options)
      flows << Flow.create(TABLE_PHYSICAL_DST, 0, {}, nil, flow_options)

      flows << Flow.create(TABLE_MAC_ROUTE,             0, {}, nil, flow_options)

      flows << Flow.create(TABLE_METADATA_LOCAL,        0, {}, nil, flow_options)
      flows << Flow.create(TABLE_METADATA_ROUTE,        0, {}, nil, flow_options)
      flows << Flow.create(TABLE_METADATA_SEGMENT,      0, {}, nil,
                           flow_options.merge(:goto_table => TABLE_METADATA_TUNNEL_IDS))
      flows << Flow.create(TABLE_METADATA_TUNNEL_IDS,   0, {}, nil, flow_options)
      flows << Flow.create(TABLE_METADATA_TUNNEL_PORTS, 0, {}, nil, flow_options)

      flows << Flow.create(TABLE_OUTPUT_CONTROLLER,     0, {}, {:output => OFPP_CONTROLLER}, flow_options)
      flows << Flow.create(TABLE_OUTPUT_DP_ROUTE_LINK,  0, {}, nil, flow_options)
      flows << Flow.create(TABLE_OUTPUT_DATAPATH,       0, {}, nil, flow_options)

      flow_options = {:cookie => @catch_flow_cookie}

      # Catches all arp packets that are from local ports.
      #
      # All local ports have the port part of metadata [0,31] zero'ed
      # at this point.
      flows << Flow.create(TABLE_VIRTUAL_SRC, 84,
                           md_create(:local => nil).merge!(:eth_type => 0x0806), nil, flow_options)

      # Next we catch all arp packets, with learning flows for
      # incoming arp packets having been handled by network/eth_port
      # specific flows.
      flows << Flow.create(TABLE_VIRTUAL_SRC, 82, {
                             :eth_type => 0x0806,
                             :tunnel_id => 0,
                           }, nil, flow_options)

      flows << Flow.create(TABLE_VIRTUAL_SRC, 80, {
                             :eth_type => 0x0806,
                           }, nil, flow_options)

      flow_options = {:cookie => @test_flow_cookie}

      # Add any test flows here.

      @datapath.add_flows(flows)
    end

    def switch_ready
      # There's a short period of time between the switch being
      # activated and features_reply installing flow.
      @datapath.tunnel_manager.create_all_tunnels

      #
      # Send messages that will start initializing the switch.
      #

      @datapath.send_message(Trema::Messages::FeaturesRequest.new)
      @datapath.send_message(Trema::Messages::PortDescMultipartRequest.new)
    end

    def features_reply(message)
      debug "transaction_id: %#x" % message.transaction_id
      debug "n_buffers: %u" % message.n_buffers
      debug "n_tables: %u" % message.n_tables
      debug "capabilities: %u" % message.capabilities
    end

    def handle_port_desc(port_desc)
      debug "handle_port_desc: #{port_desc.inspect}"

      if @datapath.datapath_map.nil?
        warn "switch: cannot initialize ports without a valid datapath database entry (0x%016x)" % @datapath.dpid
        return
      end

      port = Port.new(@datapath, port_desc, true)
      @ports[port_desc.port_no] = port

      if port.port_number == OFPP_LOCAL
        @datapath.mod_port(port.port_number, :no_flood)

        port.extend(PortLocal)
        port.hw_addr = port_desc.hw_addr
        port.ipv4_addr = @datapath.ipv4_address

        network = @datapath.network_manager.network_by_uuid('nw-public')

      elsif port.port_info.name =~ /^eth/
        @datapath.mod_port(port.port_number, :flood)

        port.extend(PortHost)

        network = @datapath.network_manager.network_by_uuid('nw-public')

      elsif port.port_info.name =~ /^vif-/
        @datapath.mod_port(port.port_number, :no_flood)

        vif_map = Vnet::ModelWrappers::Vif[port_desc.name]

        if vif_map.nil?
          error "error: Could not find uuid: #{port_desc.name}"
          return
        end

        network = @datapath.network_manager.network_by_uuid(vif_map.batch.network.commit.uuid)

        if network.class == NetworkPhysical
          port.extend(PortPhysical)
        elsif network.class == NetworkVirtual
          port.extend(PortVirtual)
        else
          raise("Unknown network type.")
        end

        port.hw_addr = Trema::Mac.new(vif_map.mac_addr)
        port.ipv4_addr = IPAddr.new(vif_map.ipv4_address, Socket::AF_INET) if vif_map.ipv4_address

        vif_map.batch.update(:active_datapath_id => @datapath.datapath_map.id).commit

      elsif port.port_info.name =~ /^t-/
        @datapath.mod_port(port.port_number, :no_flood)

        port.extend(PortTunnel)
      else
        @datapath.mod_port(port.port_number, :no_flood)

        error "Unknown interface type: #{port.port_info.name}"
        return
      end

      network.add_port(port, true) if network
      port.install
    end

    def port_status(message)
      debug "name: #{message.name}"
      debug "reason: #{message.reason}"
      debug "port_no: #{message.port_no}"
      debug "hw_addr: #{message.hw_addr}"
      debug "state: %#x" % message.state

      case message.reason
      when OFPPR_ADD
        debug "adding port"
        self.handle_port_desc(message)

      when OFPPR_DELETE
        debug "deleting port"

        port = @ports.delete(message.port_no)

        if port.nil?
          debug "port status could not delete uninitialized port: #{message.port_no}"
          return
        end

        port.uninstall

        if port.network
          network = port.network
          network.del_port(port, true)

          if network.ports.empty?
            @datapath.network_manager.remove(network)
            @datapath.tunnel_manager.delete_tunnel_port(network.network_id, @datapath.dpid)
            dispatch_event("network/deleted", network_id: network.network_id, dpid: @datapath.dpid)
          end
        end

        if port.port_info.name =~ /^vif-/
          vif_map = Vnet::ModelWrappers::Vif[message.name]
          vif_map.batch.update(:active_datapath_id => nil).commit
        end

      end
    end

    def packet_in(message)
      port = @ports[message.match.in_port]

      @datapath.packet_manager.async.packet_in(port, message) if port
    end

    def update_topology(dpid, network_id)
      debug "[switch] update_topology: dpid => #{dpid}, network_id => #{network_id}"
      @datapath.tunnel_manager.delete_tunnel_port(network_id, dpid)
    end

  end

end
