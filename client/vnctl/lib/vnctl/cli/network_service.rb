# -*- coding: utf-8 -*-

module Vnctl::Cli
  class NetworkService < Base
    namespace :network_services
    api_suffix "network_services"

    add_modify_shared_options {
      option_display_name
      option :interface_uuid, :type => :string, :desc => "The interface uuid for this network service."
      option :incoming_port, :type => :numeric, :desc => "The incoming port for this network service."
      option :outgoing_port, :type => :numeric, :desc => "The outgoing port for this network service."
    }

    set_required_options [:type]

    add_modify_shared_options
    option_uuid
    option :type, :type => :string, :desc => "Deprecated. Use mode instead."
    option :mode, :type => :string, :desc => "The mode of this service."
    define_add

    add_modify_shared_options
    define_modify

    define_show
    define_del
  end
end
