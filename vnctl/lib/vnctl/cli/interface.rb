# -*- coding: utf-8 -*-

module Vnctl::Cli
  class Interface < Base
    namespace :interfaces
    api_suffix "/api/interfaces"

    add_modify_shared_options {
      option :network_uuid, :type => :string, :desc => "The uuid of the network this interface is in."
      option :mac_address, :type => :string, :desc => "The mac address for this interface."
      option :ipv4_address, :type => :string, :desc => "The first ip lease for this interface."
      option :ingress_filtering_enabled, :type => :boolean, :desc => "Flag that decides whether or not ingress filtering (security groups) is enabled."
      option :port_name, :type => :string, :desc => "The port name for this interface."
      option :owner_datapath_uuid, :type => :string, :desc => "The uuid of the datapath that owns this interface."
      option :mode, :type => :string, :desc => "The type of this interface."
    }

    define_standard_crud_commands

    define_relation :security_groups
  end
end
