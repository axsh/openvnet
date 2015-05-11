# -*- coding: utf-8 -*-

module Vnctl::Cli
  class DnsService < Base
    namespace :dns_services
    api_suffix "dns_services"

    add_modify_shared_options {
      option :public_dns, :type => :string, :desc => "Public DNS Server addresses(separated by `.`)."
    }

    set_required_options [:network_service_uuid]

    add_modify_shared_options
    option :network_service_uuid, :type => :string, :desc => "Network service uuid."
    define_add

    add_modify_shared_options
    define_modify

    define_show
    define_del

    define_relation :dns_records, :require_relation_uuid_label => false do |relation|
      relation.option :uuid, :type => :string,
        :desc => "Dns record uuid."
      relation.option :name, :type => :string, :required => true,
        :desc => "The name for this record."
      relation.option :ipv4_address, :type => :string, :required => true,
        :desc => "The ipv4 address for this record."
    end
  end
end
