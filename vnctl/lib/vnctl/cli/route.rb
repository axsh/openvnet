# -*- coding: utf-8 -*-

module Vnctl::Cli
  class Route < Base
    namespace :route
    api_suffix "/api/routes"

    add_modify_shared_options {
      option :vif_uuid, :type => :string, :desc => "Vif uuid for this route."
      option :route_link_uuid, :type => :string, :required => true,
        :desc => "Route link uuid for this route."
      option :ipv4_address, :type => :string, :required => true,
        :desc => "IPv4 address for this route."
      option :ipv4_prefix, :type => :numeric, :desc => "IPv4 prefix for this route."
      option :ingress, :type => :boolean, :desc => "Flag to determine if this is an ingress route."
      option :egress, :type => :boolean, :desc => "Flag to determine if this is an egress route."
    }

    define_standard_crud_commands
  end
end
