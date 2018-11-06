# -*- coding: utf-8 -*-

module Vnctl::Cli
  class MacLease < Base
    namespace :mac_leases
    api_suffix "mac_leases"

    add_shared_options {
      option :mrg_uuid, :type => :string, :desc => "The mac range group to use for interface."
      option :mac_range_group_uuid, :type => :string, :desc => "The mac range group to use for interface."
      option :mac_address, :type => :string, :desc => "The mac address to lease"
      option :segment_uuid, :type => :string, :desc => "The uuid of the segment."
    }

    add_modify_shared_options {
      option_uuid
      option :interface_uuid, :type => :string, :desc => "The uuid of the interface that this mac lease is tied to."
    }
    set_required_options []

    define_standard_crud_commands
  end
end
