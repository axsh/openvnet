# -*- coding: utf-8 -*-

module Vnctl::Cli
  class RouteLink < Base
    namespace :route_links
    api_suffix "route_links"

    add_modify_shared_options {
      option :mac_address, :type => :string, :required => true,
       :desc => "The mac address for this route link."
    }
    set_required_options [:mac_address]

    define_standard_crud_commands
  end
end
