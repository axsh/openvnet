# -*- coding: utf-8 -*-

module Vnctl::Cli
  class Network < Base
    namespace :networks
    api_suffix 'networks'

    add_shared_options {
      option :mode, :type => :string, :desc => 'Can be either physical or virtual.'
      option :network_mode, :type => :string, :desc => 'Can be either physical or virtual.'
      option :segment_uuid, :type => :string, :desc => 'The uuid of the segment this network is in.'
      option :ipv4_network, :type => :string, :desc => 'IPv4 network address.'
      option :ipv4_prefix, :type => :numeric, :desc => 'IPv4 mask size (1 < prefix < 32).'
    }

    add_shared_options {
      option :topology_uuid, :type => :string, :desc => "The uuid of the topology this network is in."
    }

    add_modify_shared_options {
      option_display_name
      option :domain_name, :type => :string, :desc => 'DNS domain name.'
    }

    set_required_options [:ipv4_network]

    define_standard_crud_commands
  end
end
