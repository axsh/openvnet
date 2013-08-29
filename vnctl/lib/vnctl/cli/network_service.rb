# -*- coding: utf-8 -*-

module Vnctl::Cli
  class NetworkService < Base
    namespace :network_service
    api_suffix "/api/network_services"

    add_modify_shared_options {
      option_display_name
      option :vif_uuid, :type => :string, :desc => "The vif uuid for this network service."
      option :incoming_port, :type => :numeric, :desc => "The incoming port for this network service."
      option :outgoing_port, :type => :numeric, :desc => "The outgoing port for this network service."
    }

    define_standard_crud_commands
  end
end
