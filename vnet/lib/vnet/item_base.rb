# -*- coding: utf-8 -*-

module Vnet

  class ItemBase

    attr_reader :id
    attr_reader :installed

    def initialize(params)
      @installed = false
    end

    def installed?
      @installed == true
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
      "#{log_type}: #{message}" + (values ? " (#{values})" : '')
    end

  end

  class ItemDpBase < ItemBase

    def initialize(params)
      @installed = false
      @dp_info = params[:dp_info]
      @id = params[:id]
    end

    def installed?
      @installed == true
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} #{log_type}: #{message}" + (values ? " (#{values})" : '')
    end

  end

  class ItemDpUuid < ItemDpBase

    attr_reader :uuid

    def initialize(params)
      @installed = false
      @dp_info = params[:dp_info]

      map = params[:map]
      @id = map.id
      @uuid = map.uuid
    end

    def installed?
      @installed == true
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
