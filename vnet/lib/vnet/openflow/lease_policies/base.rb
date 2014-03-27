# -*- coding: utf-8 -*-

module Vnet::Openflow::LeasePolicies

  class Base
    include Celluloid::Logger

    attr_reader :mode
    attr_reader :uuid

    def initialize(params)
      @dp_info = params[:dp_info]

      map = params[:map]

      @uuid = map.uuid
      @mode = map.mode
    end

    def to_hash
      {
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
