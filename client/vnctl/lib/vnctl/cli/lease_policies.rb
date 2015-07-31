# -*- coding: utf-8 -*-

module Vnctl::Cli
  class LeasePolicy < Base
    namespace :lease_policies
    api_suffix "lease_policies"

    add_modify_shared_options {
      option :mode, :type => :string, :desc => "The mode for this lease policy. (reserved for future use)"
      option :timing, :type => :string, :desc => "The timing when the lease will be assigned."
    }

    define_standard_crud_commands

    define_relation :networks do |relation|
      relation.option :ip_range_group_uuid, :type => :string, :required => true,
        :desc => "The ip range group uuid for this policy in this network."
    end

    define_relation :ip_lease_containers
    define_relation :interfaces
  end
end
