# -*- coding: utf-8 -*-

module Vnet

  class ItemBase

    attr_reader :id
    attr_reader :installed

    def initialize(params)
      @dp_info = params[:dp_info]

      # TODO: Consider removing manager.
      @manager = params[:manager]

      @installed = false
    end

    def install
    end    

    def uninstall
    end    

    def try_install
      (@installed == false) && install 
      @installed = true
    end

    def try_uninstall
      @installed, was_installed = false, @installed
      (was_installed == true) && uninstall 
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
