# -*- coding: utf-8 -*-

module Vnctl::Cli
  class Vif < Base
    namespace :vif
    api_suffix "/api/vifs"

    add_modify_shared_options {
      option :network_uuid, :type => :string, :desc => "The uuid of the network this vif is in."
      option :mac_addr, :type => :string, :desc => "The mac address for this vif."
      option :owner_datapath_uuid, :type => :string, :desc => "The uuid of the datapath that owns this vif."
      option :active_datapath_uuid, :type => :string, :desc => "The uuid of this vif's active datapath."
    }

    add_required_options [:mac_addr]

    option_uuid
    option :ipv4_address, :type => :string, :desc => "The first ip lease for this vif."
    add_modify_shared_options
    define_add

    add_modify_shared_options
    define_modify

    define_show
    define_del
  end
end
