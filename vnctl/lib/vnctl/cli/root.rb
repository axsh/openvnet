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
    vnctl_register(C::Network, "networks")
    vnctl_register(C::NetworkService, "network services")
    vnctl_register(C::RouteLink, "route links")
    vnctl_register(C::Routes, "routes")
  end
end
