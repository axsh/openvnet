# -*- coding: utf-8 -*-

module Vnctl::Cli
  class Network < Base
    namespace :network
    api_suffix "/api/networks"

    add_modify_shared_options {
      option_display_name
      option :ipv4_network, :type => :string, :desc => "IPv4 network address."
      option :ipv4_prefix, :type => :numeric, :desc => "IPv4 mask size (1 < prefix < 32)."
      option :domain_name, :type => :string, :desc => "DNS domain name."
      option :dc_network_uuid, :type => :string, :desc => "Physical network uuid."
      option :network_mode, :type => :string, :desc => "Can be either physical or virtual."
      option :editable, :type => :boolean, :desc => "Flag that decides whether or not we can edit this network."
    }

    add_required_options [:display_name, :ipv4_network]

    define_standard_crud_commands

    class DhcpRanges < Base
      namespace :dhcp_ranges
      api_suffix "/api/networks"

      desc "add NETWORK_UUID RANGE_BEGIN RANGE_END", "Adds a new dhcp range to a network."
      option_uuid
      def add(network_uuid, range_begin, range_end)
        params = options.merge({
          :network_uuid => network_uuid,
          :range_begin => range_begin,
          :range_end => range_end
        })
        puts post("#{suffix}/#{network_uuid}/dhcp_ranges", :query => params)
      end

      desc "show NETWORK_UUID", "Shows all dhcp ranges in a network."
      def show(network_uuid)
        puts get("#{suffix}/#{network_uuid}/dhcp_ranges")
      end

      desc "del NETWORK_UUID DHCP_RANGE_UUID(S)",
        "Removes dhcp ranges from a network."
      def del(base_uuid, *rel_uuids)
        puts rel_uuids.map { |rel_uuid|
          delete("#{suffix}/#{base_uuid}/dhcp_ranges/#{rel_uuid}")
        }.join("\n")
      end
    end

    register(DhcpRanges, :dhcp_ranges, "dhcp_ranges OPTIONS",
      "subcommand to manage dhcp ranges for a network")
  end
end
