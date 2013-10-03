# -*- coding: utf-8 -*-

module Vnctl::Cli
  class Interface < Base
    namespace :interface
    api_suffix "/api/interfaces"

    add_modify_shared_options {
      option :network_uuid, :type => :string, :desc => "The uuid of the network this interface is in."
      option :mac_address, :type => :string, :desc => "The mac address for this interface."
      option :owner_datapath_uuid, :type => :string, :desc => "The uuid of the datapath that owns this interface."
      option :active_datapath_uuid, :type => :string, :desc => "The uuid of this interface's active datapath."
    }

    add_required_options [:mac_address]

    option_uuid
    option :ipv4_address, :type => :string, :desc => "The first ip lease for this interface."
    add_modify_shared_options
    define_add

    add_modify_shared_options
    define_modify

    define_show
    define_del
  end
end
