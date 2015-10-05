# -*- coding: utf-8 -*-

module Vnctl::Cli
  class IpLeaseContainer < Base
    namespace :ip_lease_containers
    api_suffix 'ip_lease_containers'

    define_standard_crud_commands

    desc "ip_leases UUID", "Shows the ip leases of a specific lease container."
    def ip_leases(uuid)
      puts Vnctl.webapi.get("#{suffix}/#{uuid}/ip_leases")
    end
  end
end
