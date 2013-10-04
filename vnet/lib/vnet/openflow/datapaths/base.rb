# -*- coding: utf-8 -*-

module Vnet::Openflow::Datapaths

  class Base
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_accessor :id
    attr_accessor :uuid

    def initialize(params)
      @dp_info = params[:dp_info]
      @manager = params[:manager]

      map = params[:map]

      @id = map.id
      @uuid = map.uuid
    end
    
    # def cookie(tag = nil)
    #   value = @id | (COOKIE_PREFIX_INTERFACE << COOKIE_PREFIX_SHIFT)
    #   tag.nil? ? value : (value | (tag << COOKIE_TAG_SHIFT))
    # end

    def to_hash
      { :id => @id,
        :uuid => @uuid,
      }
    end

    def install
    end

    def uninstall
      debug "interfaces: removing flows..."

      # cookie_value = self.cookie
      # cookie_mask = COOKIE_PREFIX_MASK | COOKIE_ID_MASK

      # @dp_info.del_cookie(cookie_value, cookie_mask)
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} datapaths/base: #{message}" + (values ? " (#{values})" : '')
    end

  end

end
