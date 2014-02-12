# -*- coding: utf-8 -*-

module Vnet::Openflow::Translations

  class Base < Vnet::Openflow::ItemBase
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_reader :uuid
    attr_reader :mode

    attr_reader :interface_id

    def initialize(params)
      super

      map = params[:map]

      @id = map.id
      @uuid = map.uuid
      @mode = map.mode.to_sym

      @interface_id = map.interface_id
      @passthrough = map.passthrough == 1
    end

    def cookie
      @id | COOKIE_TYPE_TRANSLATION
    end

    def to_hash
      Vnet::Openflow::Translation.new(id: @id,
                                      uuid: @uuid,
                                      mode: @mode)
    end

    def install
    end

    def uninstall
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} translation/base: #{message}" + (values ? " (#{values})" : '')
    end

  end

end
