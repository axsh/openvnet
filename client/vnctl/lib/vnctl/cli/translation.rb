# -*- coding: utf-8 -*-

module Vnctl::Cli
  class Translation < Base
    namespace :translations
    api_suffix "translations"

    add_modify_shared_options {
      option :interface_uuid, :type => :string, :desc => "This interface uuid for this translation."
      option :mode, :type => :string, :desc => "The mode for this translation."
      option :passthrough, :type => :boolean, :desc => "Flag that sets if this translation is passthrough or not."
    }

    set_required_options [:interface_uuid, :mode]

    define_standard_crud_commands

    define_mode_relation(:static_address) do | mode |
      mode.option :ingress_ipv4_address, :type => :string, :required => true,
         :desc => "The ingress address for this static address translations"
      mode.option :egress_ipv4_address, :type => :string, :required => true,
         :desc => "The egress address for this static address translation"
      mode.option :ingress_port_number, :type => :string,
         :desc => "The ingress port number"
      mode.option :egress_port_number, :type => :string,
         :desc => "The egress port number"
      mode.option :route_link_uuid, :type => :string,
         :desc => "The route link uuid"
      mode.option :ingress_network_uuid, :type => :string,
         :desc => "The uuid of the ingress network"
      mode.option :egress_network_uuid, :type => :string,
         :desc => "The uuid of the egress network"
    end
  end
end
