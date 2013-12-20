# -*- coding: utf-8 -*-

module Vnctl::Cli
  class VlanTranslation < Base
    namespace :vlan_translation
    api_suffix "/api/vlan_translations"

    add_modify_shared_options {
      option :translation_uuid, :type => :string, :desc => "The translation uuid for this vlan translation."
      option :mac_address, :type => :string, :desc => "The mac address for this vlan translation."
      option :vlan_id, :type => :numeric, :desc => "The vlan id for this vlan translation."
      option :network_id, :type => :numeric, :desc => "The network id for this vlan translation."
    }

    set_required_options [:network_id]

    define_standard_crud_commands
  end
end
