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
    autoload :DnsService, 'vnctl/cli/dns_service'
    autoload :IpLease, 'vnctl/cli/ip_lease'
    autoload :IpRangeGroup, 'vnctl/cli/ip_range_group'
    autoload :LeasePolicy, 'vnctl/cli/lease_policies'
    autoload :MacLease, 'vnctl/cli/mac_lease'
    autoload :Network, 'vnctl/cli/network'
    autoload :NetworkService, 'vnctl/cli/network_service'
    autoload :Root, 'vnctl/cli/root'
    autoload :Route, 'vnctl/cli/route'
    autoload :RouteLink, 'vnctl/cli/route_link'
    autoload :Interface, 'vnctl/cli/interface'
    autoload :SecurityGroup, 'vnctl/cli/security_group'
    autoload :Translation, 'vnctl/cli/translation'
    autoload :VlanTranslation, 'vnctl/cli/vlan_translation'
  end

  module Configuration
    autoload :Vnctl, 'vnctl/configuration/vnctl'
  end

  def self.run(*args)
    Cli::Root.start(*args)
  end
end
