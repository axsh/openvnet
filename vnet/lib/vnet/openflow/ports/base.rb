# -*- coding: utf-8 -*-

module Vnet::Openflow::Ports

  module Install
    def install
      @installed = true
      super
    end
  end

  class Base
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_reader :port_info
    attr_reader :cookie

    attr_accessor :network_id
    attr_accessor :mac_addresses

    attr_accessor :interface_id

    # Work-around...
    attr_accessor :dst_id
    attr_accessor :tunnel_id

    def extend(m)
      # `install` method will set true to @installed automatically
      m.class_eval { prepend Install }
      super
    end

    def initialize(dp_info, port_info)
      @dp_info = dp_info
      @port_info = port_info

      @cookie = self.port_number | COOKIE_TYPE_PORT

      @installed = false
    end

    def port_number
      @port_info.port_no
    end
    alias_method :id, :port_number

    def port_name
      @port_info.name
    end

    def port_hw_addr
      @port_info.hw_addr
    end

    def port_type
      :unknown
    end

    def to_hash
      { :port_number => self.port_number,
        :port_hw_addr => self.port_hw_addr,
        :name => self.port_name,
        :type => self.port_type,
        :ipv4_address => @ipv4_addr,
        :network_id => @network_id,
      }
    end

    def install
      error "port: No install action implemented for this port."
    end

    def installed?
      !!@installed
    end

    def uninstall
      debug "port: Removing flows..."

      @dp_info.del_cookie(@cookie)
    end

  end

end
