# -*- coding: utf-8 -*-

module Vnet::Openflow::Ports

  class Base < Vnet::ItemDpBase
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_reader :port_info
    attr_reader :cookie

    attr_accessor :interface_id

    # Work-around...
    attr_accessor :dst_datapath_id
    attr_accessor :tunnel_id

    alias_method :port_number, :id
    alias_method :port_desc, :port_info

    def initialize(params)
      super

      @port_info = params[:port_desc]

      @cookie = self.port_number | COOKIE_TYPE_PORT
    end

    def log_type
      'port/base'
    end

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
      Vnet::Openflow::Port.new(id: @id,
                               port_number: self.port_number,
                               port_hw_addr: self.port_hw_addr,
                               name: self.port_name,
                               type: self.port_type)
    end

    def install
      error "port: No install action implemented for this port."
    end

    def uninstall
      debug "port: Removing flows..."

      @dp_info.del_cookie(@cookie)
    end

  end

end
