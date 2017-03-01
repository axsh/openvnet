# -*- coding: utf-8 -*-

module Vnctl::Cli
  class RouteLink < Base
    namespace :route_links
    api_suffix "route_links"

    add_shared_options {
      option :topology_uuid, :type => :string, :desc => "The uuid of the topology this network is in."
    }

    add_modify_shared_options {
      option :mac_address, :type => :string, :required => false,
       :desc => "The mac address for this route link."
    }

    define_standard_crud_commands
  end
end
