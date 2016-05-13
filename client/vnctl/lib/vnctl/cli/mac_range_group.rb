# -*- coding: utf-8 -*-

module Vnctl::Cli
  class MacRangeGroup < Base
    namespace :mac_range_groups
    api_suffix "mac_range_groups"

    add_modify_shared_options {
      option :allocation_type, :type => :string, :desc => "The way your mac addresses are going to be allocated."
    }

    define_standard_crud_commands

    define_relation :mac_ranges, :require_relation_uuid_label => false do |relation|
      relation.option :begin_mac_address, :type => :string,
        :desc => "The mac address at which our range begins."
      relation.option :end_mac_address, :type => :string,
        :desc => "The mac address at which our range ends."
    end

  end
end
