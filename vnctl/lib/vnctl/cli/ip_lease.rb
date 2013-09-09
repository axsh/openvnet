# -*- coding: utf-8 -*-

module Vnctl::Cli
  class IpLease < Base
    namespace :ip_lease
    api_suffix "/api/ip_leases"

    add_modify_shared_options {
      option :network_uuid, :type => :string, :desc => "The network to lease this ip in."
      option :vif_uuid, :type => :string, :desc => "The uuid of the vif to lease this ip to."
      option :ip_address_uuid, :type => :string, :desc => "The uuid of the ip address to lease."
      option :alloc_type, :type => :string, :desc => "The alloc type for this ip address."
    }
    add_required_options [:network_uuid, :vif_uuid, :ip_address_uuid]

    define_standard_crud_commands
  end
end
