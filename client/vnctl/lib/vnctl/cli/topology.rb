# -*- coding: utf-8 -*-

module Vnctl::Cli
  class Topology < Base
    namespace :topologies
    api_suffix "topologies"

    add_modify_shared_options {
      option :mode, :type => :string, :desc => "The mode for this topology."
    }

    define_standard_crud_commands

    define_relation :networks, :require_relation_uuid_label => false do |relation|
      relation.option :network_uuid, :type => :string, :required => true,
        :desc => "The network uuid."

      # relation.option :begin_mac_address, :type => :string,
      #   :desc => "The mac address at which our range begins."
      # relation.option :end_mac_address, :type => :string,
      #   :desc => "The mac address at which our range ends."
    end

  end
end
