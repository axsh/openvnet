# -*- coding: utf-8 -*-

module Vnet::Openflow::LeasePolicies

  class Base
    include Celluloid::Logger

    attr_reader :id
    attr_reader :uuid
    attr_reader :mode

    def initialize(params)
      @dp_info = params[:dp_info]

      map = params[:map]

      @id = map.id
      @uuid = map.uuid
      @mode = map.mode
    end

    def to_hash
      {
        :id => self.id,
        :uuid => self.uuid,
        :mode => self.mode
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
