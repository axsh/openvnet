# -*- coding: utf-8 -*-

module Vnet::Models

  class Topology < Base
    taggable 'tp'

    plugin :paranoia_is_deleted

    one_to_many :topology_networks

    # TODO: Add assosiate_dependencies.

  end

end
