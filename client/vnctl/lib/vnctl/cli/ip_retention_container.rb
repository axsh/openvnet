# -*- coding: utf-8 -*-

module Vnctl::Cli
  class IpRetentionContainer < Base
    namespace :ip_retention_containers
    api_suffix "ip_retention_containers"

    add_modify_shared_options {
      option :lease_time, type: :numeric, desc: "The lease time for ip retentions this container."
      option :grace_time, type: :numeric, desc: "The grace time for ip retentions in this container."
    }

    define_standard_crud_commands

    desc "ip_retentions UUID", "Shows the ip retentions of a specific retention container."
    def ip_retentions(uuid)
      puts Vnctl.webapi.get("#{suffix}/#{uuid}/ip_retentions")
    end
  end
end
