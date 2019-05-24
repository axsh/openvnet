# -*- coding: utf-8 -*-

# Based on code from Trema. (http://github.com/trema/trema)
#
# Trema is released under the GNU General Public License version 2.0 or MIT License:
#
# http://www.gnu.org/licenses/gpl-2.0.html
# http://www.opensource.org/licenses/MIT

# frozen_string_literal: true

module Vnet::Openflow::Trema
  # OpenFlow switch.
  class Switch
    # include Celluloid
    include Vnet::Logger
    include Vnet::Watchdog

    attr_reader :error_message

    class InitError < StandardError; end

    include Pio

    OPENFLOW_HEADER_LENGTH = 8

    def initialize(socket)
      @socket = socket
    end

    def init
      exchange_messages message_to_send: Hello, message_to_receive: Hello
      exchange_messages(message_to_send: Echo::Request,
                        message_to_receive: Echo::Reply)
      @features_reply = exchange_messages(message_to_send: Features::Request,
                                          message_to_receive: Features::Reply)
      self
    end

    def datapath_id
      raise 'Switch is not initialized.' unless @features_reply
      @features_reply.datapath_id
    end
    alias dpid datapath_id

    def write(message)
      debug "Sending #{message.inspect}"
      @socket.write message.to_binary
    end

    def write_binary(binary)
      @socket.write binary
    end

    def read
      OpenFlow.read read_openflow_binary
    end

    private

    def exchange_messages(message_to_send:, message_to_receive:)
      write message_to_send.new
      expect_receiving message_to_receive
    end

    # rubocop:disable MethodLength
    def expect_receiving(expected_message_klass)
      loop do
        message = read
        debug "Received #{message}"
        case message
        when expected_message_klass
          return message
        when Echo::Request
          write Echo::Reply.new(xid: message.xid)
        when PacketIn, PortStatus # , FlowRemoved (not implemented yet)
          return
        when OpenFlow10::Error::HelloFailed, OpenFlow13::Error::HelloFailed
          @error_message = message
          fail InitError, message.description
        else
          raise "Failed to receive #{expected_message_klass} message"
        end
      end
    end
    # rubocop:enable MethodLength

    def read_openflow_binary
      header_binary = drain(OPENFLOW_HEADER_LENGTH)
      header = OpenFlow::Header.read(header_binary)
      body_binary = drain(header.message_length - OPENFLOW_HEADER_LENGTH)
      raise if (header_binary + body_binary).length != header.message_length
      header_binary + body_binary
    end

    def drain(length)
      buffer = ''
      loop do
        buffer += @socket.readpartial(length - buffer.length)
        break if buffer.length == length
      end
      buffer
    end
  end
end
