# -*- coding: utf-8 -*-

module Vnctl::Cli
  class IpLease < Base
    namespace :ip_leases
    api_suffix "ip_leases"

    add_modify_shared_options {
      option :enable_routing, :type => :boolean, :desc => "Flag that decides whether or not routing is enabled for this ip lease."
    }
    set_required_options [:network_uuid, :mac_lease_uuid, :ipv4_address]

    define_standard_crud_commands

    desc "attach UUID", "Attach a #{namespace} to an interface."
    # option_uuid
    option :interface_uuid, :type => :string, :required => false,
    :desc => "Attach to interface UUID, using the first mac lease if not specified."
    option :mac_lease_uuid, :type => :string, :required => false,
    :desc => "Attach to mac lease UUID and its interface."
    define_method(:attach) do |uuid|
      puts Vnctl.webapi.put("#{suffix}/#{uuid}/attach", options)
    end

    desc "release UUID", "Release a #{namespace} from its interface."
    # option_uuid
    define_method(:release) do |uuid|
      puts Vnctl.webapi.put("#{suffix}/#{uuid}/release", options)
    end

  end
end
