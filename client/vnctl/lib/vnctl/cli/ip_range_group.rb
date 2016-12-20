# -*- coding: utf-8 -*-

module Vnctl::Cli
  class IpRangeGroup < Base
    namespace :ip_range_groups
    api_suffix 'ip_range_groups'

    add_modify_shared_options {
      option :allocation_type, :type => :string, :desc => 'The way your ip addresses are going to be allocated.'
    }

    define_standard_crud_commands

    define_relation :ranges, :require_relation_uuid_label => false do |relation|
      relation.option :begin_address, :type => :string,
        :desc => 'The address at which our range begins.'
      relation.option :end_address, :type => :string,
        :desc => 'The address at which our range ends.'
    end
  end
end
