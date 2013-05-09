# -*- coding: utf-8 -*-

require 'racket'
require 'trema/actions'
require 'trema/instructions'
require 'trema/messages'

module Vnmgr::VNet::Openflow

  class Controller < Trema::Controller
    # include OpenFlowConstants

    attr_reader :switches

    def initialize service_openflow
      @service_openflow = service_openflow
      @default_ofctl = OvsOfctl.new

      @switches = {}
    end

    def find_network_id(network_id)
      switches.each { |dpid,switch|
        network = switch.networks[network_id]
        return switch, network if network
      }

      return nil, nil
    end

    def start
      p "starting OpenFlow controller."
    end

    def switch_ready datapath_id
      p "switch_ready from %#x." % datapath_id

      # Sometimes ovs changes the datapath ID and reconnects.
      old_switch = switches[datapath_id]
      
      if old_switch
        p "found old bridge: datapath_id:%016x" % old_switch[0]

        switches.delete(old_switch[0])
        #old_switch[1].networks.each { |network_id,network| @service_openflow.destroy_network(network, false) }
      end

      # There is no need to clean up the old switch, as all the
      # previous flows are removed. Just let it rebuild everything.
      #
      # This might not be optimal in cases where the switch got
      # disconnected for a short period, as Open vSwitch has the
      # ability to keep flows between sessions.
      switch = switches[datapath_id] = Switch.new(Datapath.new(self, datapath_id))
      # switch.update_bridge_ipv4
      switch.switch_ready

      flows = []
      # flows << Flow.new(0, 2, {:in_port => OFPP_LOCAL}, {:resubmit => 1})
      flows << Flow.new(0, 3, {
                          :ip => nil,
                          :eth_src => Trema::Mac.new('08:00:27:5d:84:1c'),
                          :eth_dst => Trema::Mac.new('08:00:27:5d:84:1b'),
                        },{
                          :output => 1
                        },{
                          :idle_timeout => 50,
                          :hard_timeout => 100,
                        })

      switch.datapath.add_flows(flows)
    end

    def features_reply datapath_id, message
      p "features_reply from %#x." % datapath_id

      p message.inspect

      raise "No switch found." unless switches[datapath_id]
      switches[datapath_id].features_reply(message)
    end

    def port_desc_multipart_reply datapath_id, message
      p "port_desc_multipart_reply from %#x." % datapath_id

      p message.inspect

      raise "No switch found." unless switches[datapath_id]
      message.parts.each { |port_descs| switches[datapath_id].port_desc_multipart_reply(port_descs) }
    end

    def port_status datapath_id, message
      p "port_status from %#x." % datapath_id

      raise "No switch found." unless switches[datapath_id]
      switches[datapath_id].port_status(message)
    end

    def packet_in datapath_id, message
      p "packet_in from %#x." % datapath_id

      raise "No switch found." unless switches[datapath_id]
      switches[datapath_id].packet_in(message)
    end

    def vendor datapath_id, message
      p "vendor message from #{datapath_id.to_hex}."
      p "transaction_id: #{message.transaction_id.to_hex}"
      p "data: #{message.buffer.unpack('H*')}"
    end

    def public_send_message datapath_id, message
      send_message(datapath_id, message)
    end

  end

end
