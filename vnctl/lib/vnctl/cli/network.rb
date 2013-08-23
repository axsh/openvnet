# -*- coding: utf-8 -*-

module Vnctl::Cli
  class Network < Base
    namespace :network
    api_suffix "/api/networks"

    desc "add [options]", "Creates a new network."
    option :uuid, :type => :string, :desc => "Unique uuid."
    option :display_name, :type => :string, :desc => "Human readable display name."
    option :ipv4_network, :type => :string, :desc => "IPv4 network address."
    option :ipv4_prefix, :type => :numeric, :desc => "IPv4 mask size (1 < prefix < 32)."
    option :domain_name, :type => :string, :desc => "DNS domain name."
    option :dc_network_uuid, :type => :string, :desc => "Physical network uuid."
    option :network_mode, :type => :string, :desc => "Can be either physical or virtual."
    option :editable, :type => :boolean, :desc => "Flag that decides whether or not we can edit this network."
    def add
      puts post(suffix, :query => options)
    end

    define_show("networks")

    desc "del UUIDS", "Deletes one or more networks separated by a space."
    def del(*uuids)
      puts uuids.map { |uuid|
        delete("#{suffix}/#{uuid}")
      }.join("\n")
    end
  end
end