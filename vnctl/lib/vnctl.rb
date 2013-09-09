# -*- coding: utf-8 -*-

require 'httparty'

module Vnctl
  class WebApi
    include HTTParty

    base_uri '127.0.0.1:9090'
  end

  module Cli
    autoload :Base, 'vnctl/cli/base'
    autoload :Datapath, 'vnctl/cli/datapath'
    autoload :DhcpRange, 'vnctl/cli/dhcp_range'
    autoload :Network, 'vnctl/cli/network'
    autoload :NetworkService, 'vnctl/cli/network_service'
    autoload :Root, 'vnctl/cli/root'
    autoload :Route, 'vnctl/cli/route'
    autoload :RouteLink, 'vnctl/cli/route_link'
    autoload :Vif, 'vnctl/cli/vif'
  end
end
