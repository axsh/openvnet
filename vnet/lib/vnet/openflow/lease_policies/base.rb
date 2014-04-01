# -*- coding: utf-8 -*-

module Vnet::Openflow::LeasePolicies

  class Base
    include Celluloid::Logger

    attr_reader :id
    attr_reader :uuid
    attr_reader :mode
    attr_reader :networks
    attr_reader :interfaces

    def initialize(params)
      @dp_info = params[:dp_info]

      map = params[:map]

      @id = map.id
      @uuid = map.uuid
      @mode = map.mode
      @networks = map.networks
      @interfaces = map.interfaces
    end

    def to_hash
      {
        :id => self.id,
        :uuid => self.uuid,
        :mode => self.mode,
        :networks => self.networks,
        :interfaces => self.interfaces
      }
    end

    #
    # Events: 
    #

    def install
    end    

    def uninstall
    end    

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "lease_policies/base: #{message}"
    end

  end

end
