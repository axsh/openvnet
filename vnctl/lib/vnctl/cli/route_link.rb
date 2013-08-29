# -*- coding: utf-8 -*-

module Vnctl::Cli
  class RouteLink < Base
    namespace :route_link
    api_suffic "/api/route_links"
  end

  no_tasks {
    def self.add_modify_shared_options
      option :mac_address, :type => :string, :desc => "The mac address for this route link."
    end
  }

  option_uuid
  add_modify_shared_options
  define_add

  add_modify_shared_options
  define_modify

  define_show
  define_del
end
