# -*- coding: utf-8 -*-

module VNetAPIClient

  class Datapath < ApiResource
    define_standard_crud_methods
    define_relation_methods(:networks)
    define_relation_methods(:route_links)
  end

end
