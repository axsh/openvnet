# -*- coding: utf-8 -*-

module Vnctl::Cli
  class IpRangeGroup < Base
    namespace :ip_range_groups
    api_suffix "/api/ip_range_groups"

    add_modify_shared_options {
      option :allocation_type, :type => :string, :desc => "The way your ip addresses are going to be allocated."
    }

    define_standard_crud_commands

    #TODO: The webapi doesn't use the standard uuid based association here
    # It instead creates a new range based on begin and end address so we can't
    # use the standard define_relation method. We'll have to implement this manually ;_;
    #define_relation :ip_ranges do |relation|
    #  relation.option :begin_ipv4_address, :type => :string,
    #    :desc => "The ipv4 address at which our range begins."
    #  relation.option :end_ipv4_address, :type => :string,
    #    :desc => "The ipv4 address at which our range ends."
    #end
  end
end
