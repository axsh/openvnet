# -*- coding: utf-8 -*-

require 'net/http'

module Vnctl
  autoload :WebApi, 'vnctl/webapi'

  module Cli
    autoload :Base, 'vnctl/cli/base'
    autoload :Datapath, 'vnctl/cli/datapath'
    autoload :DnsService, 'vnctl/cli/dns_service'
    autoload :IpLease, 'vnctl/cli/ip_lease'
    autoload :IpLeaseContainer, 'vnctl/cli/ip_lease_container'
    autoload :IpRangeGroup, 'vnctl/cli/ip_range_group'
    autoload :IpRetentionContainer, 'vnctl/cli/ip_retention_container'
    autoload :LeasePolicy, 'vnctl/cli/lease_policy'
    autoload :MacLease, 'vnctl/cli/mac_lease'
    autoload :MacRangeGroup, 'vnctl/cli/mac_range_group'
    autoload :Network, 'vnctl/cli/network'
    autoload :NetworkService, 'vnctl/cli/network_service'
    autoload :Root, 'vnctl/cli/root'
    autoload :Route, 'vnctl/cli/route'
    autoload :RouteLink, 'vnctl/cli/route_link'
    autoload :Interface, 'vnctl/cli/interface'
    autoload :Filter, 'vnctl/cli/filter'
    autoload :SecurityGroup, 'vnctl/cli/security_group'
    autoload :Topology, 'vnctl/cli/topology'
    autoload :Translation, 'vnctl/cli/translation'
    autoload :VlanTranslation, 'vnctl/cli/vlan_translation'
  end

  module Configuration
    autoload :Vnctl, 'vnctl/configuration/vnctl'
  end

  def self.conf
    @conf
  end

  def self.webapi
    @webapi ||= Vnctl::WebApi.new
  end
end
