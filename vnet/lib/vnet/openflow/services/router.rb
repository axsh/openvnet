# -*- coding: utf-8 -*-

require 'racket'

module Vnet::Openflow::Services

  class Router < Base

    def initialize(params)
      super
      @interface_id = params[:interface_id]
    end

    def install
      debug "service::router.install: interface_id:#{@interface_id}"
    end

  end

end
