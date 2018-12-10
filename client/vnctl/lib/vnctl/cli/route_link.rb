# -*- coding: utf-8 -*-

module Vnctl::Cli
  class RouteLink < Base
    namespace :route_links
    api_suffix "route_links"

    add_shared_options {
      option :mac_address, :type => :string, :required => false, :desc => "The mac address for this route link."
      option :mrg_uuid, :type => :string, :desc => "The mac range group to use for this route link."
      option :mac_range_group_uuid, :type => :string, :desc => "The mac range group to use for this route link."
      option :topology_uuid, :type => :string, :desc => "The uuid of the topology this route link is in."
    }

    define_standard_crud_commands
  end
end
