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

    def switch_ready(datapath_id)
      info "switch_ready from %#x." % datapath_id
      initialize_datapath(datapath_id)
    end

    def switch_disconnected(datapath_id)
      info "switch_disconnected from %#x." % datapath_id
      terminate_datapath(datapath_id)
    end

    def features_reply(dpid, message)
      info "features_reply from %#x." % dpid

      datapath = datapath(dpid) || raise("No datapath found.")
      datapath.switch.async.features_reply(message)
    end

    def port_desc_multipart_reply(dpid, message)
      info "port_desc_multipart_reply from %#x." % dpid

      dp_info = dp_info(dpid)
      return unless dp_info

      message.parts.each { |port_descs|
        debug "ports: %s" % port_descs.ports.collect { |each| each.port_no }.sort.join( ", " )

        port_descs.ports.each { |port_desc| dp_info.port_manager.async.insert(port_desc) }
      }
    end

    def port_status(dpid, message)
      debug "port_status from %#x." % dpid

      datapath = datapath(dpid)
      datapath.switch.async.port_status(message) if datapath && datapath.switch
    end

    def packet_in(dpid, message)
      dp_info = dp_info(dpid)
      return unless dp_info

      case message.cookie >> COOKIE_PREFIX_SHIFT
      when COOKIE_PREFIX_INTERFACE
        dp_info.interface_manager.async.packet_in(message)
      when COOKIE_PREFIX_TRANSLATION
        dp_info.translation_manager.async.packet_in(message)
      when COOKIE_PREFIX_ROUTE_LINK
        dp_info.router_manager.async.packet_in(message)
      when COOKIE_PREFIX_SERVICE
        dp_info.service_manager.async.packet_in(message)
      when COOKIE_PREFIX_CONNECTION
        dp_info.connection_manager.async.packet_in(message)
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

    def reset_datapath(dpid)
      terminate_datapath(dpid)
      initialize_datapath(dpid)
    end

    def initialize_datapath(dpid)
      info "initialize datapath actor. dpid: 0x%016x" % dpid

      terminate_datapath(dpid)

      # There is no need to clean up the old switch, as all the
      # previous flows are removed. Just let it rebuild everything.
      #
      # This might not be optimal in cases where the switch got
      # disconnected for a short period, as Open vSwitch has the
      # ability to keep flows between sessions.
      datapath = Datapath.new(self, dpid, OvsOfctl.new(dpid))
      @datapaths[dpid] = { datapath: datapath, dp_info: datapath.dp_info }

      datapath.async.create_switch
    end

    def terminate_datapath(dpid)
      datapath_map = @datapaths.delete(dpid) || return
      datapath = datapath_map[:datapath] || return

      info "terminating datapath actor. dpid: 0x%016x" % dpid

      datapath.reset_datapath_info
      datapath.terminate
    end

    def update_vlan_translation
      datapath.switch.async.update_vlan_translation
    end

    def datapath(dpid)
      @datapaths[dpid] && @datapaths[dpid][:datapath]
    end

    def dp_info(dpid)
      @datapaths[dpid] && @datapaths[dpid][:dp_info]
    end
  end

end
