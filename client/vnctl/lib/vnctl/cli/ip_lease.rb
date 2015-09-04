# -*- coding: utf-8 -*-

module Vnctl::Cli
  class IpLease < Base
    namespace :ip_leases
    api_suffix "ip_leases"

    add_modify_shared_options {
      option :network_uuid, :type => :string, :desc => "The network to lease this ip in."
      option :mac_lease_uuid, :type => :string, :desc => "The mac lease that this ip lease is tried to."
      option :ipv4_address, :type => :string, :desc => "The ipv4 address to lease."
      option :enable_routing, :type => :boolean, :desc => "Flag that decides whether or not routing is enabled for this ip lease."
    }
    set_required_options [:network_uuid, :mac_lease_uuid, :ipv4_address]

    define_standard_crud_commands
  end
end
