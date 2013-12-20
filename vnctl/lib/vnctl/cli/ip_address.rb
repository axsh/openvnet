# -*- coding: utf-8 -*-

module Vnctl::Cli
  class IpAddress < Base
    namespace :ip_address
    api_suffix "/api/ip_addresses"

    add_modify_shared_options {
      option :network_uuid, :type => :string, :desc => "The network to define this ip address in."
      option :ipv4_address, :type => :string, :desc => "The actual ipv4 address."
    }
    set_required_options [:network_uuid, :ipv4_address]

    define_standard_crud_commands
  end
end
