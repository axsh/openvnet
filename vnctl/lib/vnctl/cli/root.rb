# -*- coding: utf-8 -*-

module Vnctl::Cli
  class Root < Thor
    C = Vnctl::Cli
    no_tasks {
      def self.vnctl_register(klass, operations)
        register(klass, klass.namespace, klass.namespace, "Operations for #{operations}.")
      end
    }

    vnctl_register(C::Datapath, "datapaths")
    vnctl_register(C::IpLease, "ip leases")
    vnctl_register(C::MacLease, "mac leases")
    vnctl_register(C::Network, "networks")
    vnctl_register(C::NetworkService, "network services")
    vnctl_register(C::Route, "routes")
    vnctl_register(C::RouteLink, "route links")
    vnctl_register(C::Interface, "interfaces")
    vnctl_register(C::SecurityGroup, "security groups")
    vnctl_register(C::Translation, "translations")
    vnctl_register(C::VlanTranslation, "vlan translations")
  end
end
