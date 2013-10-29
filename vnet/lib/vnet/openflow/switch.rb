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

      @dpid = @datapath.dpid
      @dpid_s = "0x%016x" % @datapath.dpid

      cookie_manager = @datapath.cookie_manager

      @catch_flow_cookie   = cookie_manager.acquire(:switch)
      @default_flow_cookie = cookie_manager.acquire(:switch)
      @test_flow_cookie    = cookie_manager.acquire(:switch)
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
      fo_local_md  = flow_options.merge(md_create(:local => nil))
      fo_remote_md = flow_options.merge(md_create(:remote => nil))

      fo_controller_md = flow_options.merge(md_create(local: nil,
                                                      no_controller: nil))

      flows << Flow.create(TABLE_CLASSIFIER, 2, {
                             :in_port => OFPP_CONTROLLER
                           },
                           nil,
                           fo_controller_md.merge(:goto_table => TABLE_CONTROLLER_PORT))

      flows << Flow.create(TABLE_CLASSIFIER, 1, {:tunnel_id => 0}, nil, flow_options)
      flows << Flow.create(TABLE_CLASSIFIER, 0, {}, nil,
                           fo_remote_md.merge(:goto_table => TABLE_TUNNEL_PORTS))
      flows << Flow.create(TABLE_EDGE_SRC,   0, {}, {:output => Controller::OFPP_CONTROLLER}, {:cookie => COOKIE_PREFIX_TRANSLATION << COOKIE_PREFIX_SHIFT} )
      flows << Flow.create(TABLE_EDGE_DST,   0, {}, nil, flow_options) 
      flows << Flow.create(TABLE_HOST_PORTS,         0, {}, nil, flow_options)
      flows << Flow.create(TABLE_TUNNEL_PORTS,       0, {}, nil, flow_options)
      flows << Flow.create(TABLE_TUNNEL_NETWORK_IDS, 0, {}, nil, flow_options)
      flows << Flow.create(TABLE_VIF_PORTS,          0, {}, nil, flow_options)
      flows << Flow.create(TABLE_LOCAL_PORT,         0, {}, nil, flow_options)
      flows << Flow.create(TABLE_CONTROLLER_PORT,    0, {}, nil, flow_options)

      flows << Flow.create(TABLE_NETWORK_SRC_CLASSIFIER, 0, {}, nil, flow_options)
      flows << Flow.create(TABLE_NETWORK_DST_CLASSIFIER, 0, {}, nil, flow_options)

      flows << Flow.create(TABLE_VIRTUAL_SRC,  0, {}, nil, flow_options)
      # flows << Flow.create(TABLE_VIRTUAL_SRC,  40, {:eth_type => 0x0800}, nil, flow_options)
      flows << Flow.create(TABLE_PHYSICAL_SRC, 0, {}, nil, flow_options)
      flows << Flow.create(TABLE_PHYSICAL_SRC, 40, {:eth_type => 0x0800}, nil, flow_options)
      flows << Flow.create(TABLE_PHYSICAL_SRC, 40, {:eth_type => 0x0806}, nil, flow_options)

      flows << Flow.create(TABLE_ROUTER_CLASSIFIER, 0, {}, nil,
                           flow_options.merge(:goto_table => TABLE_NETWORK_DST_CLASSIFIER))
      flows << Flow.create(TABLE_ROUTER_INGRESS,    0, {}, nil, flow_options)
      flows << Flow.create(TABLE_ROUTE_LINK,        0, {}, nil, flow_options)
      flows << Flow.create(TABLE_ROUTER_DST,        0, {}, nil, flow_options)

      flows << Flow.create(TABLE_ARP_LOOKUP,            0, {}, nil, flow_options)

      flows << Flow.create(TABLE_VIRTUAL_DST,           0, {}, nil, flow_options)
      flows << Flow.create(TABLE_PHYSICAL_DST,          0, {}, nil, flow_options)

      flows << Flow.create(TABLE_VIRTUAL_DST,  30, {:eth_dst => MAC_BROADCAST}, nil,
                           flow_options.merge(:goto_table => TABLE_FLOOD_SIMULATED))
      flows << Flow.create(TABLE_PHYSICAL_DST, 30, {:eth_dst => MAC_BROADCAST}, nil,
                           flow_options.merge(:goto_table => TABLE_FLOOD_SIMULATED))

      flows << Flow.create(TABLE_OUTPUT_INTERFACE,   0, {}, nil, flow_options)
      flows << Flow.create(TABLE_INTERFACE_VIF, 0, {}, nil, flow_options)

      flows << Flow.create(TABLE_MAC_ROUTE,             0, {}, nil, flow_options)

      flows << Flow.create(TABLE_FLOOD_SIMULATED, 0, {}, nil,
                           flow_options.merge(:goto_table => TABLE_FLOOD_LOCAL))
      flows << Flow.create(TABLE_FLOOD_LOCAL,        0, {}, nil, flow_options)
      flows << Flow.create(TABLE_FLOOD_ROUTE,        0, {}, nil, flow_options)
      flows << Flow.create(TABLE_FLOOD_ROUTE, 10,
                           md_create(:remote => nil), nil,
                           flow_options)
      flows << Flow.create(TABLE_FLOOD_SEGMENT,      0, {}, nil,
                           flow_options.merge(:goto_table => TABLE_FLOOD_TUNNELS))
      flows << Flow.create(TABLE_FLOOD_SEGMENT, 10,
                           md_create(:remote => nil), nil,
                           flow_options)
      flows << Flow.create(TABLE_FLOOD_TUNNELS,      0, {}, nil, flow_options)

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

      # Temporary hack to load the public network.
      @datapath.network_manager.async.item(uuid: 'nw-public')
    end

    def features_reply(message)
      debug log_format("transaction_id: %#x" % message.transaction_id)
      debug log_format("n_buffers: %u" % message.n_buffers)
      debug log_format("n_tables: %u" % message.n_tables)
      debug log_format("capabilities: %u" % message.capabilities)
    end

    def port_status(message)
      debug log_format("port_status #{message.name}",
                       "reason:#{message.reason} port_no:#{message.port_no} " +
                       "hw_addr:#{message.hw_addr} state:%#x" % message.state)

      case message.reason
      when OFPPR_ADD
        debug log_format("adding port")
        @datapath.port_manager.insert(message)
      when OFPPR_DELETE
        debug log_format("deleting port")
        @datapath.port_manager.remove(message)
      end
    end

    def update_topology(dpid, network_id)
      debug log_format("update_topology", "dpid:#{dpid} network_id:#{network_id}")
      @datapath.tunnel_manager.delete_tunnel_port(network_id, dpid)
    end

    def update_vlan_translation
      # TODO
    end
    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dpid_s} switch: #{message}" + (values ? " (#{values})" : '')
    end

  end

end
