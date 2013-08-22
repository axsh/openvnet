# -*- coding: utf-8 -*-

require 'httparty'

module Vnctl
  class WebApi
    include HTTParty

    base_uri '127.0.0.1:9090'
  end

  module Cli
    autoload :Base, 'vnctl/cli/base'
    autoload :Root, 'vnctl/cli/root'
    autoload :Datapath, 'vnctl/cli/datapath'
  end
end
