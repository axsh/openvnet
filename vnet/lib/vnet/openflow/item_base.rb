# -*- coding: utf-8 -*-

module Vnet::Openflow

  class ItemBase

    attr_reader :id

    def initialize(params)
      @dp_info = params[:dp_info]

      # TODO: Consider removing manager.
      @manager = params[:manager]
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} #{log_type}: #{message}" + (values ? " (#{values})" : '')
    end

  end

end
