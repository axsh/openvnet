# -*- coding: utf-8 -*-

module Vnctl::Cli
  class DhcpRange < Base
    namespace :dhcp_range
    api_suffix "/api/dhcp_ranges"

    add_modify_shared_options {
      option :network_uuid, :type => :string, :desc => "The network to define this dhcp range in."
      option :range_begin, :type => :string, :desc => "The first ipv4 in this range."
      option :range_end, :type => :string, :desc => "The last ipv4 in this range."
    }
    add_required_options [:network_uuid, :range_begin, :range_end]

    define_standard_crud_commands
  end
end
