# -*- coding: utf-8 -*-

module Vnctl::Cli
  class IpLease < Base
    namespace :ip_lease
    api_suffix "/api/ip_leases"

    add_modify_shared_options {
      option :network_uuid, :type => :string, :desc => "The network to lease this ip in."
      option :interface_uuid, :type => :string, :desc => "The uuid of the interface to lease this ip to."
      option :ip_address_uuid, :type => :string, :desc => "The uuid of the ip address to lease."
    }
    add_required_options [:network_uuid, :interface_uuid, :ip_address_uuid]

    define_standard_crud_commands
  end
end
