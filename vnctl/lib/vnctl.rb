# -*- coding: utf-8 -*-

require 'httparty'

module Vnctl

  def self.conf
    @conf
  end

  autoload :WebApi, 'vnctl/webapi'

  module Cli
    autoload :Base, 'vnctl/cli/base'
    autoload :Datapath, 'vnctl/cli/datapath'
    autoload :IpAddress, 'vnctl/cli/ip_address'
    autoload :IpLease, 'vnctl/cli/ip_lease'
    autoload :MacLease, 'vnctl/cli/mac_lease'
    autoload :Network, 'vnctl/cli/network'
    autoload :NetworkService, 'vnctl/cli/network_service'
    autoload :Root, 'vnctl/cli/root'
    autoload :Route, 'vnctl/cli/route'
    autoload :RouteLink, 'vnctl/cli/route_link'
    autoload :Vif, 'vnctl/cli/interface'
  end

  module Configuration
    autoload :Vnctl, 'vnctl/configuration/vnctl'
  end
end
