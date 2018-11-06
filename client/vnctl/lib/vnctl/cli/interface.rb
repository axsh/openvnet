# -*- coding: utf-8 -*-

module Vnctl::Cli
  class Interface < Base
    namespace :interfaces
    api_suffix "interfaces"

    add_modify_shared_options {
      option :enable_routing, :type => :boolean,
        :desc => "Flag that decides whether or not routing is enabled."
      option :enable_route_translation, :type => :boolean,
        :desc => "Flag that decides whether or not route translation is enabled."
      option :owner_datapath_uuid, :type => :string,
        :desc => "The uuid of the datapath that owns this interface."
      option :enable_filtering, :type => :boolean,
        :desc => "Flags that decides whether or not filtering is enabled."
    }

    option_uuid
    add_modify_shared_options
    option :segment_uuid, :type => :string, :desc => "The uuid of the segment this interface is on."
    option :network_uuid, :type => :string, :desc => "The uuid of the network this interface is on."
    option :mrg_uuid, :type => :string, :desc => "The mac range group to use for interface."
    option :mac_range_group_uuid, :type => :string, :desc => "The mac range group to use for interface."
    option :mac_address, :type => :string, :desc => "The mac address for this interface."
    option :ipv4_address, :type => :string, :desc => "The first ip lease for this interface."
    option :port_name, :type => :string, :desc => "The port name for this interface."
    option :mode, :type => :string, :desc => "The type of this interface."
    define_add

    add_modify_shared_options
    define_modify

    define_show
    define_del
    define_rename

    # Here we do a dirty hack because the ports relation does not follow the
    # standard relation format. More specifically, it takes arguments to its
    # delete route.
    ports_relation = define_relation :ports, require_relation_uuid_label: false

    options_hash = {
      datapath_uuid: Thor::Option.new(:datapath_uuid, type: :string,
          desc: "The UUID of the dtapath this port will be on."),

      port_name: Thor::Option.new(:port_name, type: :string,
          desc: "The name of this port."),

      singular: Thor::Option.new(:singular, type: :boolean,
          desc: "A flag to decide if this port is singular or not.")
    }

    ports_relation.commands["add"].options.merge!(options_hash)
    ports_relation.commands["del"].options.merge!(options_hash)

    def self.define_assoc(other_name)
      other_suffix = "#{other_name}s".to_sym

      define_relation(other_suffix, only_include_show: true) { |relation|
        relation.desc "INTERFACE_UUID #{other_name.upcase}_UUID --static true/false", 'Modify association.'
        relation.option :static, :type => :boolean, :desc => "Always keep an interface associated with a #{other_name}."
        relation.define_custom_method(:modify, true) do |uuid, other_uuid, options|
          puts Vnctl.webapi.put("interfaces/#{uuid}/#{other_suffix}/#{other_uuid}", options)
        end
      }
    end

    define_assoc(:network)
    define_assoc(:segment)
    define_assoc(:route_link)

  end
end
