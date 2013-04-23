# -*- coding: utf-8 -*-

require 'racket'

module Vnmgr::VNet::Openflow

  class Controller < Trema::Controller
    # include OpenFlowConstants

    attr_reader :switches

    def initialize service_openflow
      @service_openflow = service_openflow
      # @default_ofctl = OvsOfctl.new

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

      # # We currently rely on the ovs database to figure out the
      # # bridge name, as it is randomly generated each time the
      # # bridge is created unless explicitly set by the user.
      # bridge_name = @default_ofctl.get_bridge_name(datapath_id)
      # raise "No bridge found matching: datapath_id:%016x" % datapath_id if bridge_name.nil?

      # ofctl = @default_ofctl.dup
      # ofctl.switch_name = bridge_name

      # # Sometimes ovs changes the datapath ID and reconnects.
      # old_switch = switches.find { |dpid,switch| switch.switch_name == bridge_name }
      
      # if old_switch
      #   p "found old bridge: name:#{old_switch[1].switch_name} datapath_id:%016x" % old_switch[1].datapath.datapath_id

      #   switches.delete(old_switch[0])
      #   old_switch[1].networks.each { |network_id,network| @service_openflow.destroy_network(network, false) }
      # end

      # # There is no need to clean up the old switch, as all the
      # # previous flows are removed. Just let it rebuild everything.
      # #
      # # This might not be optimal in cases where the switch got
      # # disconnected for a short period, as Open vSwitch has the
      # # ability to keep flows between sessions.
      # switches[datapath_id] = OpenFlowSwitch.new(OpenFlowDatapath.new(self, datapath_id, ofctl), bridge_name)
      # switches[datapath_id].update_bridge_ipv4
      # switches[datapath_id].switch_ready
    end

    def features_reply datapath_id, message
      p "features_reply from %#x." % datapath_id

      # raise "No switch found." unless switches.has_key? datapath_id
      # switches[datapath_id].features_reply message
    end

    def port_status datapath_id, message
      p "port_status from %#x." % datapath_id

      # raise "No switch found." unless switches.has_key? datapath_id
      # switches[datapath_id].port_status message
    end

    def packet_in datapath_id, message
      p "packet_in from %#x." % datapath_id

      # raise "No switch found." unless switches.has_key? datapath_id
      # switches[datapath_id].packet_in message
    end

    def vendor datapath_id, message
      p "vendor message from #{datapath_id.to_hex}."
      p "transaction_id: #{message.transaction_id.to_hex}"
      p "data: #{message.buffer.unpack('H*')}"
    end

  end

end
