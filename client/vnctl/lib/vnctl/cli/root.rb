# -*- coding: utf-8 -*-

require 'shellwords'

module Vnctl::Cli
  class Root < Thor
    C = Vnctl::Cli

    no_tasks {
      def self.vnctl_register(klass, operations)
        register(klass, klass.namespace, klass.namespace, "Operations for #{operations}.")
      end
    }

    desc 'batch [FILE]', 'Read from file, or stdin if no file is specified'
    def batch(file_name = nil)
      if file_name.nil?
        input = $stdin
      else
        input = File.open(file_name, 'r')
      end

      say "BEGIN (#{file_name})", :yellow

      while (line = input.gets)
        line.strip!
        next if line.empty? || line[0] == '#'

        say "> #{line}", :green

        Shellwords.split(line).tap { |argv|
          Root.start argv
        }
      end

      say 'EOF', :yellow
    end

    vnctl_register(C::Datapath, 'datapaths')
    vnctl_register(C::DnsService, 'dns_services')
    vnctl_register(C::IpLease, 'ip leases')
    vnctl_register(C::IpLeaseContainer, 'ip lease containers')
    vnctl_register(C::IpRangeGroup, 'ip ranges')
    vnctl_register(C::IpRetentionContainer, 'ip retention containers')
    vnctl_register(C::LeasePolicy, 'lease policies')
    vnctl_register(C::MacLease, 'mac leases')
    vnctl_register(C::MacRangeGroup, 'mac ranges')
    vnctl_register(C::Network, 'networks')
    vnctl_register(C::NetworkService, 'network services')
    vnctl_register(C::Route, 'routes')
    vnctl_register(C::RouteLink, 'route links')
    vnctl_register(C::Interface, 'interfaces')
    vnctl_register(C::Filter, 'filters')
    vnctl_register(C::Segment, 'segments')
    vnctl_register(C::Topology, 'topologies')
    vnctl_register(C::Translation, 'translations')
  end
end
