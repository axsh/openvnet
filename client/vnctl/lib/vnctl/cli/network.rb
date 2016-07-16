# -*- coding: utf-8 -*-

module Vnctl::Cli
  class Network < Base
    namespace :networks
    api_suffix "networks"

    add_modify_shared_options {
      option_display_name
      option :segment_uuid, :type => :string, :desc => "The uuid of the segment this network is in."
      option :ipv4_network, :type => :string, :desc => "IPv4 network address."
      option :ipv4_prefix, :type => :numeric, :desc => "IPv4 mask size (1 < prefix < 32)."
      option :domain_name, :type => :string, :desc => "DNS domain name."
      option :network_mode, :type => :string, :desc => "Can be either physical or virtual."
      option :editable, :type => :boolean, :desc => "Flag that decides whether or not we can edit this network."
    }

    set_required_options [:display_name, :ipv4_network]

    define_standard_crud_commands
  end
end
