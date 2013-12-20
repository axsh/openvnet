# -*- coding: utf-8 -*-

module Vnctl::Cli
  class MacLease < Base
    namespace :mac_lease
    api_suffix "/api/mac_leases"

    add_modify_shared_options {
      option :interface_uuid, :type => :string, :desc => "The uuid of the interface that this mac lease is tried to."
      option :mac_address, :type => :string, :desc => "The mac address to lease"
    }
    set_required_options [:mac_address, :interface_uuid]

    define_standard_crud_commands
  end
end
