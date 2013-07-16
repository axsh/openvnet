# -*- coding: utf-8 -*-

require 'racket'
require 'trema/actions'
require 'trema/instructions'
require 'trema/messages'

module Vnet::Openflow

  class Controller < Trema::Controller
    include TremaTasks
    include Celluloid::Logger

    attr_reader :switches
    attr_accessor :trema_thread

    def initialize(service_openflow)
      @service_openflow = service_openflow

      @switches = {}
    end

    def start
      info "starting OpenFlow controller."
    end

    def switch_ready(datapath_id)
      info "switch_ready from %#x." % datapath_id

      # Sometimes ovs changes the datapath ID and reconnects.
      old_switch = @switches.delete(datapath_id)
      
      if old_switch
        info "found old bridge: datapath_id:%016x" % datapath_id

        #old_switch[1].networks.each { |network_id,network| @service_openflow.destroy_network(network, false) }
      end

      # There is no need to clean up the old switch, as all the
      # previous flows are removed. Just let it rebuild everything.
      #
      # This might not be optimal in cases where the switch got
      # disconnected for a short period, as Open vSwitch has the
      # ability to keep flows between sessions.
      switch = switches[datapath_id] = Switch.new(Datapath.new(self, datapath_id, OvsOfctl.new(datapath_id)))
      switch.async.switch_ready
    end

    def features_reply(datapath_id, message)
      info "features_reply from %#x." % datapath_id

      switch = switches[datapath_id] || raise("No switch found.")
      switch.async.features_reply(message)
    end

    def port_desc_multipart_reply(datapath_id, message)
      info "port_desc_multipart_reply from %#x." % datapath_id

      switch = switches[datapath_id] || raise("No switch found.")

      message.parts.each { |port_descs| 
        port_descs.ports.each { |port_desc| 
          switch.async.update_bridge_hw(port_desc.hw_addr.dup) if port_desc.name =~ /^eth/
        }
      }

      message.parts.each { |port_descs| 
        debug "ports: %s" % port_descs.ports.collect { |each| each.port_no }.sort.join( ", " )

        port_descs.ports.each { |port_desc| switch.async.handle_port_desc(port_desc) }
      }
      
    end

    def port_status(datapath_id, message)
      debug "port_status from %#x." % datapath_id

      switch = switches[datapath_id] || raise("No switch found.")
      switch.async.port_status(message)
    end

    def packet_in(datapath_id, message)
      switch = switches[datapath_id] || raise("No switch found.")
      switch.async.packet_in(message)
    end

    def vendor(datapath_id, message)
      debug "vendor message from #{datapath_id.to_hex}."
      debug "transaction_id: #{message.transaction_id.to_hex}"
      debug "data: #{message.buffer.unpack('H*')}"
    end

    def public_send_message(datapath_id, message)
      raise "public_send_message must be called from the trema thread" unless Thread.current == @trema_thread
      send_message(datapath_id, message)
    end

    def public_send_flow_mod(datapath_id, message)
      raise "public_send_flow_mod must be called from the trema thread" unless Thread.current == @trema_thread
      send_flow_mod(datapath_id, message)
    end

    def public_send_packet_out(datapath_id, message, port_no)
      raise "public_send_packet_out must be called from the trema thread" unless Thread.current == @trema_thread
      send_packet_out(datapath_id, {
                        :packet_in => message,
                        :actions => [Trema::Actions::SendOutPort.new(:port_number => port_no)]
                      })
    end

  end

end
