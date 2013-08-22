# -*- coding: utf-8 -*-

module Vnctl::Cli
  class Root < Thor
    register(Vnctl::Cli::Datapath, Vnctl::Cli::Datapath.namespace,
      "datapath", "Operations for datapaths.")
  end
end
