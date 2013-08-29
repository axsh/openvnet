# -*- coding: utf-8 -*-

module Vnctl::Cli
  class Root < Thor
    C = Vnctl::Cli
    register(C::Datapath, C::Datapath.namespace, "datapath", "Operations for datapaths.")
    register(C::Network, C::Network.namespace, "network", "Operations for networks.")
    register(C::NetworkService, C::NetworkService.namespace, "network-service", "operations for network services")
  end
end
