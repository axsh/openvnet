# -*- coding: utf-8 -*-

module Vnctl::Cli
  class RouteLink < Base
    namespace :route_link
    api_suffix "/api/route_links"

    option_uuid
    option :mac_address, :type => :string, :desc => "The mac address for this route link."
    define_add

    define_show
    define_del
  end
end
