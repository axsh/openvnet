# -*- coding: utf-8 -*-

require 'racket'
require 'trema/actions'
require 'trema/instructions'
require 'trema/messages'

module Vnet::Openflow

  class Controller < Trema::Controller
    include TremaTasks
    include Celluloid::Logger
    include Vnet::Constants::Openflow

    attr_reader :datapaths
    attr_accessor :trema_thread

    def initialize
      @datapaths = {}
    end

    def start
      info "starting OpenFlow controller."
    end

    def switch_ready(dpid)
      info "switch_ready from %#x." % dpid

      # Sometimes ovs changes the datapath ID and reconnects.
      old_datapath = @datapaths.delete(dpid)

      if old_datapath
        info "found old bridge: dpid:%016x" % dpid
      end

      # There is no need to clean up the old switch, as all the
      # previous flows are removed. Just let it rebuild everything.
      #
      # This might not be optimal in cases where the switch got
      # disconnected for a short period, as Open vSwitch has the
      # ability to keep flows between sessions.
      datapath = @datapaths[dpid] = Datapath.new(self, dpid, OvsOfctl.new(dpid))

      datapath.async.create_switch
    end

    def features_reply(dpid, message)
      info "features_reply from %#x." % dpid

      datapath = @datapaths[dpid] || raise("No datapath found.")
      datapath.switch.async.features_reply(message)
    end

    def port_desc_multipart_reply(dpid, message)
      info "port_desc_multipart_reply from %#x." % dpid

      datapath = @datapaths[dpid]
      return if datapath.nil?

      message.parts.each { |port_descs|
        debug "ports: %s" % port_descs.ports.collect { |each| each.port_no }.sort.join( ", " )

        port_descs.ports.each { |port_desc| datapath.port_manager.async.insert(port_desc) }
      }
    end

    def port_status(dpid, message)
      debug "port_status from %#x." % dpid

      datapath = @datapaths[dpid]
      datapath.switch.async.port_status(message) if datapath && datapath.switch
    end

    def packet_in(dpid, message)
      datapath = @datapaths[dpid]
      return if datapath.nil?

      case message.cookie >> COOKIE_PREFIX_SHIFT
      when COOKIE_PREFIX_INTERFACE
        datapath.interface_manager.async.packet_in(message)
      when COOKIE_PREFIX_TRANSLATION
        datapath.translation_manager.async.packet_in(message)
      when COOKIE_PREFIX_SERVICE
        datapath.service_manager.async.packet_in(message)
      when COOKIE_PREFIX_ROUTE, COOKIE_PREFIX_ROUTE_LINK
        datapath.route_manager.async.packet_in(message)
      else
        datapath.packet_manager.async.packet_in(message)
      end
    end

    def vendor(dpid, message)
      debug "vendor message from #{dpid.to_hex}."
      debug "transaction_id: #{message.transaction_id.to_hex}"
      debug "data: #{message.buffer.unpack('H*')}"
    end

    def public_send_message(dpid, message)
      raise "public_send_message must be called from the trema thread" unless Thread.current == @trema_thread
      send_message(dpid, message)
    end

    def public_send_flow_mod(dpid, message)
      raise "public_send_flow_mod must be called from the trema thread" unless Thread.current == @trema_thread
      send_flow_mod(dpid, message)
    end

    def public_send_packet_out(dpid, message, port_no)
      raise "public_send_packet_out must be called from the trema thread" unless Thread.current == @trema_thread
      send_packet_out(dpid, {
                        :packet_in => message,
                        :actions => [Trema::Actions::SendOutPort.new(:port_number => port_no)]
                      })
    end

    def update_topology(dpid, network_id)
      debug "[controller]: update_topology: dpid => #{dpid}, network_id => #{network_id}"
      datapath = @datapaths[@datapaths.keys[0]]
      datapath.switch.async.update_topology(dpid, network_id)
    end

    def update_vlan_translation
      datapath.switch.async.update_vlan_translation
    end
  end

end
