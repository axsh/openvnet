# -*- coding: utf-8 -*-

module Vnctl::Cli
  class Route < Base
    namespace :route
    api_suffix "/api/routes"

    add_modify_shared_options {
      option :interface_uuid, :type => :string, :desc => "Interface uuid for this route."
      option :route_link_uuid, :type => :string,:desc => "Route link uuid for this route."
      option :network_uuid, :type => :string, :desc => "Network uuid for this route."
      option :ipv4_network, :type => :string, :desc => "IPv4 network for this route."
      option :ipv4_prefix, :type => :numeric, :desc => "IPv4 prefix for this route."
      option :ingress, :type => :boolean, :desc => "Flag to determine if this is an ingress route."
      option :egress, :type => :boolean, :desc => "Flag to determine if this is an egress route."
    }

    add_required_options [:ipv4_address, :network_uuid, :route_link_uuid]

    define_standard_crud_commands
  end
end
